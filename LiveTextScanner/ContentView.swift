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
        NavigationStack {
            CameraView(viewModel: container.cameraViewModel)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .history:
                        HistoryView(viewModel: container.historyViewModel)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppDependencyContainer())
}
