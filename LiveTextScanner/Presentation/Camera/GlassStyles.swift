//
//  GlassStyles.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

extension View {
    /// Applies a Liquid Glass capsule background on iOS 26+, falls back to `.ultraThinMaterial`.
    @ViewBuilder
    func glassPill(tint: Color = .clear) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(tint), in: .capsule)
        } else {
            self
                .background(tint.opacity(0.25), in: .capsule)
                .background(.ultraThinMaterial, in: .capsule)
        }
    }

    /// Applies an interactive Liquid Glass circle background on iOS 26+, falls back to `.ultraThinMaterial`.
    @ViewBuilder
    func glassCircle() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .circle)
        } else {
            self.background(.ultraThinMaterial, in: .circle)
        }
    }
}
