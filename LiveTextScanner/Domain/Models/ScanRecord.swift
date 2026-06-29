//
//  ScanRecord.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Foundation
import SwiftData

@Model
final class ScanRecord {
    var id: UUID
    /// Sequential capture number assigned at save time. Stable across launches and shown to the user.
    var number: Int = 0
    var date: Date
    var text: String
    var thumbnailData: Data?
    /// BCP-47 language tag, e.g. "en", "fr", "he"
    var language: String?
    /// Raw per-line strings from the frame, before deduplication
    var sourceRegions: [String]

    init(
        id: UUID = UUID(),
        number: Int = 0,
        date: Date = .now,
        text: String,
        thumbnailData: Data? = nil,
        language: String? = nil,
        sourceRegions: [String] = []
    ) {
        self.id = id
        self.number = number
        self.date = date
        self.text = text
        self.thumbnailData = thumbnailData
        self.language = language
        self.sourceRegions = sourceRegions
    }
}

extension ScanRecord: Comparable {
    static func < (lhs: ScanRecord, rhs: ScanRecord) -> Bool {
        lhs.date > rhs.date
    }
}
