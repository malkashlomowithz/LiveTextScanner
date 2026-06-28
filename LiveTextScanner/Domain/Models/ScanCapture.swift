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

    init(id: UUID = UUID(), date: Date = .now, regions: [TextRegion]) {
        self.id = id
        self.date = date
        self.regions = regions
    }
}
