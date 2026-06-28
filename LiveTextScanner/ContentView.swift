//
//  ContentView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppDependencyContainer.self) private var container

    var body: some View {
        TabView {
            CameraView(viewModel: container.cameraViewModel)
                .tabItem { Label("Scan", systemImage: "viewfinder") }

            HistoryView(viewModel: container.historyViewModel)
                .tabItem { Label("History", systemImage: "clock") }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppDependencyContainer())
}
