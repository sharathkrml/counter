//
//  BackendManager.swift
//  counter
//

import Foundation
import Combine
import AppKit
import Darwin

enum BackendError: Error, LocalizedError {
    case pythonNotFound
    case startupTimeout
    case healthTimeout
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .pythonNotFound: return "Python interpreter not found."
        case .startupTimeout: return "Backend did not report a port in time."
        case .healthTimeout: return "Backend did not become ready in time."
        case .launchFailed(let msg): return "Failed to launch backend: \(msg)"
        }
    }
}

@MainActor
final class BackendManager: ObservableObject {
    @Published var status: BackendStatus = .stopped
    @Published var port: Int?

    let token: String

    private var process: Process?
    private var stdoutTask: Task<Void, Never>?
    private var terminateObserver: NSObjectProtocol?

    private let pythonPath: String
    private let modulePath: String
    private let dataDirectory: URL

    init(
        pythonPath: String = BackendManager.resolvePythonPath(),
        modulePath: String = BackendManager.resolveModulePath(),
        dataDirectory: URL = BackendManager.resolveDataDirectory()
    ) {
        self.pythonPath = pythonPath
        self.modulePath = modulePath
        self.dataDirectory = dataDirectory
        self.token = UUID().uuidString
        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stop()
        }
    }

    func start() async throws {
        guard process == nil else { return }
        status = .starting
        port = nil

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: pythonPath)
        proc.arguments = ["-m", "counter_backend.main"]

        var env = ProcessInfo.processInfo.environment
        env["PYTHONPATH"] = modulePath
        env["COUNTER_DATA_DIR"] = dataDirectory.path
        env["COUNTER_SESSION_TOKEN"] = token
        env["COUNTER_HOST"] = "127.0.0.1"
        env["COUNTER_PORT"] = "0"
        proc.environment = env

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        stdoutTask = Task { [weak self] in
            let handle = outPipe.fileHandleForReading
            do {
                for try await line in handle.bytes.lines {
                    if line.contains("READY port=") {
                        let parts = line.split(separator: "=")
                        if let last = parts.last, let p = Int(last.trimmingCharacters(in: .whitespaces)) {
                            await MainActor.run { self?.port = p }
                        }
                    }
                }
            } catch {
                // ignore
            }
        }

        do {
            try proc.run()
        } catch {
            status = .failed(error.localizedDescription)
            throw BackendError.launchFailed(error.localizedDescription)
        }
        process = proc

        // Wait for port
        let portDeadline = Date().addingTimeInterval(15)
        while port == nil && Date() < portDeadline {
            try? await Task.sleep(for: .milliseconds(100))
            if proc.isRunning == false { break }
        }
        guard let readyPort = port else {
            stop()
            status = .failed("Backend did not report a port.")
            throw BackendError.startupTimeout
        }

        // Poll health
        let healthDeadline = Date().addingTimeInterval(15)
        while Date() < healthDeadline {
            do {
                let url = URL(string: "http://127.0.0.1:\(readyPort)/health")!
                var req = URLRequest(url: url)
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                let (_, resp) = try await URLSession.shared.data(for: req)
                if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                    status = .ready
                    return
                }
            } catch {
                // retry
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
        stop()
        status = .failed("Backend health check timed out.")
        throw BackendError.healthTimeout
    }

    func stop() {
        stdoutTask?.cancel()
        stdoutTask = nil
        if let proc = process, proc.isRunning {
            proc.terminate()
            // wait briefly
            let deadline = Date().addingTimeInterval(3)
            while proc.isRunning && Date() < deadline {
                RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            }
            if proc.isRunning {
                kill(proc.processIdentifier, SIGKILL)
            }
        }
        process = nil
        status = .stopped
        port = nil
    }

    deinit {
        if let obs = terminateObserver { NotificationCenter.default.removeObserver(obs) }
        if let proc = process, proc.isRunning {
            proc.terminate()
        }
    }

    var baseURL: URL? {
        guard let port else { return nil }
        return URL(string: "http://127.0.0.1:\(port)")
    }

    // MARK: - Resolution helpers

    nonisolated static func resolvePythonPath() -> String {
        if let env = ProcessInfo.processInfo.environment["COUNTER_BACKEND_PYTHON"], !env.isEmpty {
            return env
        }
        let devVenv = "/Users/sharath/Documents/Github/counter/backend/.venv/bin/python"
        if FileManager.default.isExecutableFile(atPath: devVenv) {
            return devVenv
        }
        return "/usr/bin/python3"
    }

    nonisolated static func resolveModulePath() -> String {
        if let env = ProcessInfo.processInfo.environment["COUNTER_BACKEND_SRC"], !env.isEmpty {
            return env
        }
        let devSrc = "/Users/sharath/Documents/Github/counter/backend/src"
        if FileManager.default.fileExists(atPath: devSrc) {
            return devSrc
        }
        return ""
    }

    nonisolated static func resolveDataDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("com.personal.counter", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
