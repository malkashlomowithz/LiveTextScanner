//
//  DeduplicationTests.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Testing
@testable import LiveTextScanner

@Suite("SimilarityDeduplicator")
struct DeduplicationTests {

    // MARK: - Stability threshold

    @Test("Returns nil for frames below stability threshold")
    func belowStabilityThreshold() {
        let sut = SimilarityDeduplicator(stabilityThreshold: 3)
        let capture = ScanCapture.make(text: "Hello World")

        #expect(sut.process(capture) == nil)
        #expect(sut.process(capture) == nil)
    }

    @Test("Emits on reaching the stability threshold")
    func emitsOnReachingThreshold() {
        let sut = SimilarityDeduplicator(stabilityThreshold: 3)
        let capture = ScanCapture.make(text: "Hello World")

        _ = sut.process(capture)
        _ = sut.process(capture)
        let result = sut.process(capture)

        #expect(result != nil)
        #expect(result?.fullText == "Hello World")
    }

    @Test("OCR jitter within similarity threshold counts as stable")
    func similarTextCountsAsStable() {
        let sut = SimilarityDeduplicator(stabilityThreshold: 3, similarityThreshold: 0.90)

        _ = sut.process(ScanCapture.make(text: "Hello World"))
        _ = sut.process(ScanCapture.make(text: "Hello Worlb"))  // 1-char diff: similarity ≈ 0.91
        let result = sut.process(ScanCapture.make(text: "Hello World"))

        #expect(result != nil)
    }

    @Test("Significant text change resets stability window")
    func significantChangeResetsWindow() {
        let sut = SimilarityDeduplicator(stabilityThreshold: 3)

        _ = sut.process(ScanCapture.make(text: "Hello World"))
        _ = sut.process(ScanCapture.make(text: "Hello World"))
        _ = sut.process(ScanCapture.make(text: "Completely Different"))  // resets
        _ = sut.process(ScanCapture.make(text: "Hello World"))
        let result = sut.process(ScanCapture.make(text: "Hello World"))  // only 2 after reset

        #expect(result == nil)
    }

    @Test("Same stable text is not emitted twice")
    func sameTextNotReEmitted() {
        let sut = SimilarityDeduplicator(stabilityThreshold: 3)
        let capture = ScanCapture.make(text: "Hello World")

        _ = sut.process(capture)
        _ = sut.process(capture)
        let first = sut.process(capture)   // emitted
        let second = sut.process(capture)  // suppressed

        #expect(first != nil)
        #expect(second == nil)
    }

    @Test("Reset clears state so same text can be emitted again")
    func resetAllowsReEmission() {
        let sut = SimilarityDeduplicator(stabilityThreshold: 3)
        let capture = ScanCapture.make(text: "Hello World")

        _ = sut.process(capture)
        _ = sut.process(capture)
        _ = sut.process(capture)  // emitted once

        sut.reset()

        _ = sut.process(capture)
        _ = sut.process(capture)
        let result = sut.process(capture)  // should emit again after reset

        #expect(result != nil)
    }

    @Test("Distinct similar text passes through as separate events (no aggressive merging)")
    func distinctSimilarTextPassesThrough() {
        // "Cat" vs "Bat": similarity = 1 - (1/3) ≈ 0.67, well below 0.90 threshold
        let sut = SimilarityDeduplicator(stabilityThreshold: 3, similarityThreshold: 0.90)

        _ = sut.process(ScanCapture.make(text: "Cat"))
        _ = sut.process(ScanCapture.make(text: "Cat"))
        let resultA = sut.process(ScanCapture.make(text: "Cat"))

        _ = sut.process(ScanCapture.make(text: "Bat"))
        _ = sut.process(ScanCapture.make(text: "Bat"))
        let resultB = sut.process(ScanCapture.make(text: "Bat"))

        #expect(resultA != nil)
        #expect(resultB != nil)
    }

    @Test("Empty capture is handled without crashing")
    func emptyCaptureHandled() {
        let sut = SimilarityDeduplicator(stabilityThreshold: 1)
        let capture = ScanCapture(regions: [])

        let result = sut.process(capture)

        #expect(result != nil)  // empty is still "stable" after 1 frame
        #expect(result?.fullText == "")
    }
}
