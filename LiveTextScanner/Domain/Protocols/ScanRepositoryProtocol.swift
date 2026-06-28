//
//  ScanRepositoryProtocol.swift
//  ScanRepositoryProtocol
//
//  Created by Malky on 28/06/2026.
//

import Foundation

/// Abstraction over scan persistence.
/// `@MainActor` because ScanRecord is a SwiftData @Model and must be accessed on the main actor.
@MainActor
protocol ScanRepositoryProtocol {
    func save(
        text: String,
        date: Date,
        language: String?,
        sourceRegions: [String],
        thumbnailData: Data?
    ) async throws

    func fetchAll() async throws -> [ScanRecord]

    /// Searches both the full text and individual source regions.
    func search(query: String) async throws -> [ScanRecord]

    func delete(id: UUID) async throws
}
