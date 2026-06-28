//
//  ScanHistoryUseCase.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Foundation

/// Manages access to the saved scan history: fetch, search, and delete.
@MainActor
final class ScanHistoryUseCase {
    private let repository: any ScanRepositoryProtocol

    init(repository: some ScanRepositoryProtocol) {
        self.repository = repository
    }

    func fetchAll() async throws -> [ScanRecord] {
        try await repository.fetchAll()
    }

    /// Returns all records when `query` is empty; otherwise filters by text content.
    func search(query: String) async throws -> [ScanRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return try await repository.fetchAll()
        }
        return try await repository.search(query: trimmed)
    }

    func delete(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
