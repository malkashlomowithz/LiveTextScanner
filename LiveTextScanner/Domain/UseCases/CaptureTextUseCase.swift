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

    /// Saves `capture` to the repository, deriving detected languages from its regions.
    func execute(_ capture: ScanCapture) async throws {
        try await repository.save(
            text: capture.fullText,
            date: capture.date,
            detectedLanguages: capture.detectedLanguages,
            sourceRegions: capture.regions.map(\.text),
            thumbnailData: nil
        )
    }
}
