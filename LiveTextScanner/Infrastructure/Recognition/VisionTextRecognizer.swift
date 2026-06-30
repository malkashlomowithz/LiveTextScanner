//
//  VisionTextRecognizer.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Vision
import CoreVideo
import NaturalLanguage

/// Concrete OCR engine backed by Apple's Vision framework.
/// Swap this out by supplying a different `TextRecognitionProtocol` conformance — no other files change.
final class VisionTextRecognizer: TextRecognitionProtocol, @unchecked Sendable {

    /// BCP-47 language codes passed to Vision. Empty means automatic language detection.
    var recognitionLanguages: [String] = []

    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [TextRegion] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        // When no languages are pinned, let Vision auto-select the best model per frame.
        request.automaticallyDetectsLanguage = recognitionLanguages.isEmpty
        if !recognitionLanguages.isEmpty {
            request.recognitionLanguages = recognitionLanguages
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try handler.perform([request])

        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        // One NLLanguageRecognizer instance per call; reset() between observations.
        let nlRecognizer = NLLanguageRecognizer()

        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            nlRecognizer.reset()
            nlRecognizer.processString(candidate.string)
            let language = nlRecognizer.dominantLanguage?.rawValue
            return TextRegion(
                text: candidate.string,
                boundingBox: observation.boundingBox,
                detectedLanguage: language
            )
        }
    }
}
