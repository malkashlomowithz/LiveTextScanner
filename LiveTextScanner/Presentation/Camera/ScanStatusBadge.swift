//
//  ScanStatusBadge.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

/// Floating glass status pill that surfaces scan state at a glance.
struct ScanStatusBadge: View {
    let detectionCount: Int

    var body: some View {
        Label {
            Text(title)
                .font(.subheadline)
        } icon: {
            Image(systemName: icon)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassPill(tint: tint)
        .animation(.easeInOut(duration: 0.2), value: detectionCount > 0)
    }

    private var hasDetections: Bool { detectionCount > 0 }

    private var title: String {
        if hasDetections {
            "\(detectionCount) detected"
        } else {
            "Scanning…"
        }
    }

    private var icon: String {
        hasDetections ? "text.viewfinder" : "viewfinder"
    }

    private var tint: Color {
        hasDetections ? Color("SecondaryColor") : .clear
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            ScanStatusBadge(detectionCount: 0)
            ScanStatusBadge(detectionCount: 3)
        }
    }
    .ignoresSafeArea()
}
