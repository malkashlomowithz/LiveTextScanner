//
//  TextRegion.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Foundation
import CoreGraphics

/// A single text region detected in one camera frame.
/// `boundingBox` uses Vision's normalized coordinate space: origin at bottom-left, values in 0–1.
struct TextRegion: Identifiable, Hashable, Sendable {
    let id: UUID
    let text: String
    let boundingBox: CGRect
    /// BCP-47 tag detected by NLLanguageRecognizer for this region, e.g. "en", "fr", "zh-Hans".
    /// `nil` when recognition produced insufficient text for a confident prediction.
    let detectedLanguage: String?

    init(id: UUID = UUID(), text: String, boundingBox: CGRect, detectedLanguage: String? = nil) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.detectedLanguage = detectedLanguage
    }
}
