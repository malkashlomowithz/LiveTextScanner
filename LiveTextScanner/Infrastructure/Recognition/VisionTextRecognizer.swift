//
//  VisionTextRecognizer.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Vision
import CoreVideo

/// Concrete OCR engine backed by Apple's Vision framework.
/// Swap this out by supplying a different `TextRecognitionProtocol` conformance — no other files change.
final class VisionTextRecognizer: TextRecognitionProtocol, @unchecked Sendable {

    /// BCP-47 language codes passed to Vision. Empty means automatic language detection.
    var recognitionLanguages: [String] = []

    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [TextRegion] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        if !recognitionLanguages.isEmpty {
            request.recognitionLanguages = recognitionLanguages
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try handler.perform([request])

        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return TextRegion(text: candidate.string, boundingBox: observation.boundingBox)
        }
    }
}
