//
//  InMemoryStore.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Foundation

/// Lightweight in-memory `ScanRepositoryProtocol` for unit tests.
/// No SwiftData container required — create and inject directly into any use case under test.
@MainActor
final class InMemoryStore: ScanRepositoryProtocol {

    /// Exposed so tests can assert saved state without calling `fetchAll()`.
    private(set) var records: [ScanRecord] = []

    func save(
        text: String,
        date: Date,
        language: String?,
        sourceRegions: [String],
        thumbnailData: Data?
    ) async throws {
        let nextNumber = (records.map(\.number).max() ?? 0) + 1
        records.append(
            ScanRecord(
                number: nextNumber,
                date: date,
                text: text,
                thumbnailData: thumbnailData,
                language: language,
                sourceRegions: sourceRegions
            )
        )
    }

    func fetchAll() async throws -> [ScanRecord] {
        records.sorted()
    }

    func search(query: String) async throws -> [ScanRecord] {
        records
            .filter { $0.text.localizedStandardContains(query) }
            .sorted()
    }

    func delete(id: UUID) async throws {
        records.removeAll { $0.id == id }
    }
}
