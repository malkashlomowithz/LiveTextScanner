//
//  GlassStyles.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

extension View {
    /// Applies a Liquid Glass capsule background.
    func glassPill(tint: Color = .clear) -> some View {
        glassEffect(.regular.tint(tint), in: .capsule)
    }

    /// Applies an interactive Liquid Glass circle background.
    func glassCircle() -> some View {
        glassEffect(.regular.interactive(), in: .circle)
    }
}
