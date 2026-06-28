//
//  TextOverlayView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

/// Draws semi-transparent highlight rectangles over detected text regions.
/// Coordinates are converted from Vision's normalized space (origin bottom-left)
/// to SwiftUI's view space (origin top-left).
struct TextOverlayView: View {
    let regions: [TextRegion]

    var body: some View {
        Canvas { context, size in
            for region in regions {
                let rect = viewRect(for: region.boundingBox, in: size)
                context.fill(Path(rect), with: .color(.yellow.opacity(0.15)))
                context.stroke(Path(rect), with: .color(.yellow), lineWidth: 2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func viewRect(for boundingBox: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: boundingBox.minX * size.width,
            y: (1 - boundingBox.maxY) * size.height,
            width: boundingBox.width * size.width,
            height: boundingBox.height * size.height
        )
    }
}
