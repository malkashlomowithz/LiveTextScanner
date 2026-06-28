//
//  TextRecognitionProtocol.swift
//  TextRecognitionProtocol
//
//  Created by Malky on 28/06/2026.
//

import CoreVideo

/// Abstraction over the OCR engine.
/// Conform to this protocol to swap Vision for any other provider (ML Kit, Tesseract, etc.)
/// without touching any domain or presentation code.
protocol TextRecognitionProtocol: AnyObject, Sendable {
    /// BCP-47 language codes to attempt during recognition. Empty array means automatic detection.
    var recognitionLanguages: [String] { get set }

    /// Recognize all text regions in a single pixel buffer.
    /// Returns regions using Vision's normalized coordinate space (origin bottom-left, values 0–1).
    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [TextRegion]
}
