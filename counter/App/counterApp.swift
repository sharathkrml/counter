//
//  counterApp.swift
//  counter
//

import SwiftUI

@main
struct counterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
