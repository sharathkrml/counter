//
//  BackendStatus.swift
//  counter
//

import Foundation

enum BackendStatus: Equatable, Sendable {
    case stopped
    case starting
    case ready
    case failed(String)
}
