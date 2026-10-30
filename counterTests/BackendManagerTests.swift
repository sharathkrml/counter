//
//  BackendManagerTests.swift
//  counterTests
//

import Testing
@testable import counter

struct BackendManagerTests {
    @Test func resolvePythonPathNonEmpty() {
        #expect(!BackendManager.resolvePythonPath().isEmpty)
    }

    @Test func resolveModulePathExists() {
        let path = BackendManager.resolveModulePath()
        #expect(!path.isEmpty)
    }
}
