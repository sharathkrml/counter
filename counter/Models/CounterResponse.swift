//
//  CounterResponse.swift
//  counter
//

import Foundation

struct CounterResponse: Codable, Sendable {
    let count: Int
}

struct HealthResponse: Codable, Sendable {
    let status: String
    let version: String
}
