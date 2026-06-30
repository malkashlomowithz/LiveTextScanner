//
//  ScanCapture.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Foundation

/// The result of one OCR pass on a single camera frame.
struct ScanCapture: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let regions: [TextRegion]

    var fullText: String {
        regions.map(\.text).joined(separator: "\n")
    }

    /// BCP-47 language tags found across all regions, sorted by frequency (most common first).
    var detectedLanguages: [String] {
        let all = regions.compactMap(\.detectedLanguage)
        let counts = Dictionary(grouping: all, by: { $0 }).mapValues(\.count)
        return counts.sorted { $0.value > $1.value }.map(\.key)
    }

    init(id: UUID = UUID(), date: Date = .now, regions: [TextRegion]) {
        self.id = id
        self.date = date
        self.regions = regions
    }
}
