//
//  LiveTextScannerApp.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

@main
struct LiveTextScannerApp: App {
    @State private var container = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
        }
    }
}
