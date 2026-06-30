//
//  MockTextRecognizer.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import CoreVideo

/// Test double for `TextRecognitionProtocol`.
/// Returns pre-programmed `TextRegion` sequences so tests run without Vision or camera hardware.
final class MockTextRecognizer: TextRecognitionProtocol, @unchecked Sendable {

    var recognitionLanguages: [String] = []

    /// Responses returned in order. Cycles back to index 0 when the list is exhausted.
    var stubbedResponses: [[TextRegion]]
    private var responseIndex = 0

    init(stubbedResponses: [[TextRegion]] = []) {
        self.stubbedResponses = stubbedResponses
    }

    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [TextRegion] {
        guard !stubbedResponses.isEmpty else { return [] }
        defer { responseIndex = (responseIndex + 1) % stubbedResponses.count }
        return stubbedResponses[responseIndex]
    }
}
