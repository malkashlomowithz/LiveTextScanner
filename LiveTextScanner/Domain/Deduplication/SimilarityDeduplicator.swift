//
//  SimilarityDeduplicator.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Foundation

/// Deduplicates text captures across consecutive camera frames using normalized edit distance.
///
/// Strategy:
/// - Text must appear in `stabilityThreshold` consecutive similar frames before being emitted.
/// - Two frames are "similar" when their normalized edit-distance similarity ≥ `similarityThreshold`.
/// - A result is emitted once per stable block — not again until the text changes significantly.
/// - Per spec: favors letting distinct text through over aggressively collapsing near-duplicates.
///
/// Marked `@unchecked Sendable` because all mutation happens on the single Task that runs
/// the scan loop in `LiveScanUseCase` — never from multiple threads simultaneously.
final class SimilarityDeduplicator: DeduplicationStrategy, @unchecked Sendable {

    private let stabilityThreshold: Int
    private let similarityThreshold: Double

    private var consecutiveCount = 0
    private var lastNormalizedText: String?
    private var lastEmittedText: String?

    /// - Parameters:
    ///   - stabilityThreshold: Consecutive similar frames required before emitting. Default: 3.
    ///   - similarityThreshold: Minimum similarity (0–1) to treat two frames as the same text. Default: 0.90.
    init(stabilityThreshold: Int = 3, similarityThreshold: Double = 0.90) {
        self.stabilityThreshold = stabilityThreshold
        self.similarityThreshold = similarityThreshold
    }

    // MARK: - DeduplicationStrategy

    func process(_ capture: ScanCapture) -> ScanCapture? {
        let normalized = normalize(capture.fullText)

        if let last = lastNormalizedText {
            let similarity = stringSimilarity(normalized, last)
            if similarity >= similarityThreshold {
                consecutiveCount += 1
            } else {
                // Text changed significantly — start fresh stability window.
                consecutiveCount = 1
                lastEmittedText = nil
            }
        } else {
            consecutiveCount = 1
        }

        lastNormalizedText = normalized

        guard consecutiveCount >= stabilityThreshold else { return nil }

        // Emit once per stable block — suppress if identical to what we already emitted.
        guard normalized != lastEmittedText else { return nil }
        lastEmittedText = normalized
        return capture
    }

    func reset() {
        consecutiveCount = 0
        lastNormalizedText = nil
        lastEmittedText = nil
    }

    // MARK: - Helpers

    private func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func stringSimilarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1.0 }
        if a.isEmpty || b.isEmpty { return 0.0 }
        let distance = levenshteinDistance(a, b)
        return 1.0 - Double(distance) / Double(max(a.count, b.count))
    }

    /// Standard Levenshtein distance using a two-row rolling array for O(min(m,n)) space.
    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }

        var prev = Array(0...b.count)
        var curr = Array(repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            curr[0] = i
            for j in 1...b.count {
                curr[j] = a[i - 1] == b[j - 1]
                    ? prev[j - 1]
                    : min(prev[j - 1], prev[j], curr[j - 1]) + 1
            }
            swap(&prev, &curr)
        }
        return prev[b.count]
    }
}
