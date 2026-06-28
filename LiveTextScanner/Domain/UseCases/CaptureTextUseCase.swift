//
//  CaptureTextUseCase.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Foundation

/// Persists a capture from the live scan session to the scan history.
@MainActor
final class CaptureTextUseCase {
    private let repository: any ScanRepositoryProtocol

    init(repository: some ScanRepositoryProtocol) {
        self.repository = repository
    }

    /// Saves `capture` to the repository.
    /// - Parameter language: BCP-47 tag of the dominant language detected, if known.
    func execute(_ capture: ScanCapture, language: String? = nil) async throws {
        try await repository.save(
            text: capture.fullText,
            date: capture.date,
            language: language,
            sourceRegions: capture.regions.map(\.text),
            thumbnailData: nil
        )
    }
}
