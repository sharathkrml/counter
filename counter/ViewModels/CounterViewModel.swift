//
//  CounterViewModel.swift
//  counter
//

import Foundation
public import Combine

@MainActor
final class CounterViewModel: ObservableObject {
    @Published var count: Int = 0
    @Published var status: BackendStatus = .stopped
    @Published var errorMessage: String?

    let backendManager: BackendManager
    private let apiClient: CounterAPIClient

    init() {
        let manager = BackendManager()
        self.backendManager = manager
        self.apiClient = CounterAPIClient(
            baseURLProvider: { manager.baseURL },
            tokenProvider: { manager.token }
        )
    }

    func start() async {
        do {
            try await backendManager.start()
            status = backendManager.status
            await refresh()
        } catch {
            status = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        do {
            count = try await apiClient.getCount()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func increment() async {
        do {
            count = try await apiClient.increment()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decrement() async {
        do {
            count = try await apiClient.decrement()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() async {
        do {
            count = try await apiClient.reset()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
