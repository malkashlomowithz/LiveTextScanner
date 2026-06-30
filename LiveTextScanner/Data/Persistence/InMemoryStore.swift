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
        detectedLanguages: [String],
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
                detectedLanguages: detectedLanguages,
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

    /// Synchronously populates the store with deterministic sample data for UI tests.
    func seedForUITesting() {
        records = [
            ScanRecord(
                number: 1,
                date: .now,
                text: "Hello World from UI test",
                detectedLanguages: ["en"],
                sourceRegions: ["Hello World from UI test"]
            ),
            ScanRecord(
                number: 2,
                date: .now.addingTimeInterval(-3600),
                text: "Bonjour le monde",
                detectedLanguages: ["fr"],
                sourceRegions: ["Bonjour le monde"]
            ),
        ]
    }
}
