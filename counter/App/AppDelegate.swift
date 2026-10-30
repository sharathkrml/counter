//
//  AppDelegate.swift
//  counter
//

import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // BackendManager is owned by ContentView's view model; best-effort cleanup.
        // In production, hold a shared manager. For now, rely on process termination.
    }
}
