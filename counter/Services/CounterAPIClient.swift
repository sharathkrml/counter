//
//  CounterAPIClient.swift
//  counter
//

import Foundation

enum APIClientError: Error, LocalizedError {
    case notConfigured
    case badResponse(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Backend is not configured."
        case .badResponse(let code): return "Backend returned HTTP \(code)."
        case .decodingFailed: return "Failed to decode backend response."
        }
    }
}

final class CounterAPIClient: Sendable {
    private let session: URLSession
    private let baseURLProvider: @Sendable () -> URL?
    private let tokenProvider: @Sendable () -> String

    init(
        session: URLSession = .shared,
        baseURLProvider: @escaping @Sendable () -> URL?,
        tokenProvider: @escaping @Sendable () -> String
    ) {
        self.session = session
        self.baseURLProvider = baseURLProvider
        self.tokenProvider = tokenProvider
    }

    private func request(path: String, method: String) async throws -> (Data, HTTPURLResponse) {
        guard let base = baseURLProvider() else { throw APIClientError.notConfigured }
        let url = base.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(tokenProvider())", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIClientError.badResponse(-1) }
        return (data, http)
    }

    func health() async throws -> HealthResponse {
        let (data, http) = try await request(path: "health", method: "GET")
        guard http.statusCode == 200 else { throw APIClientError.badResponse(http.statusCode) }
        guard let decoded = try? JSONDecoder().decode(HealthResponse.self, from: data) else {
            throw APIClientError.decodingFailed
        }
        return decoded
    }

    func getCount() async throws -> Int {
        let (data, http) = try await request(path: "v1/counter", method: "GET")
        guard http.statusCode == 200 else { throw APIClientError.badResponse(http.statusCode) }
        guard let decoded = try? JSONDecoder().decode(CounterResponse.self, from: data) else {
            throw APIClientError.decodingFailed
        }
        return decoded.count
    }

    func increment() async throws -> Int {
        let (data, http) = try await request(path: "v1/counter/increment", method: "POST")
        guard http.statusCode == 200 else { throw APIClientError.badResponse(http.statusCode) }
        guard let decoded = try? JSONDecoder().decode(CounterResponse.self, from: data) else {
            throw APIClientError.decodingFailed
        }
        return decoded.count
    }

    func decrement() async throws -> Int {
        let (data, http) = try await request(path: "v1/counter/decrement", method: "POST")
        guard http.statusCode == 200 else { throw APIClientError.badResponse(http.statusCode) }
        guard let decoded = try? JSONDecoder().decode(CounterResponse.self, from: data) else {
            throw APIClientError.decodingFailed
        }
        return decoded.count
    }

    func reset() async throws -> Int {
        let (data, http) = try await request(path: "v1/counter/reset", method: "POST")
        guard http.statusCode == 200 else { throw APIClientError.badResponse(http.statusCode) }
        guard let decoded = try? JSONDecoder().decode(CounterResponse.self, from: data) else {
            throw APIClientError.decodingFailed
        }
        return decoded.count
    }
}
