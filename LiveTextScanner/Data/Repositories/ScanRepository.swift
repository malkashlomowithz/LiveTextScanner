//
//  ScanRepository.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftData
import Foundation

/// Production repository backed by SwiftData.
@MainActor
final class ScanRepository: ScanRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(
        text: String,
        date: Date,
        detectedLanguages: [String],
        sourceRegions: [String],
        thumbnailData: Data?
    ) async throws {
        var descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.number, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let nextNumber = (try context.fetch(descriptor).first?.number ?? 0) + 1

        let record = ScanRecord(
            number: nextNumber,
            date: date,
            text: text,
            thumbnailData: thumbnailData,
            detectedLanguages: detectedLanguages,
            sourceRegions: sourceRegions
        )
        context.insert(record)
        try context.save()
    }

    func fetchAll() async throws -> [ScanRecord] {
        let descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func search(query: String) async throws -> [ScanRecord] {
        let predicate = #Predicate<ScanRecord> { record in
            record.text.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<ScanRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func delete(id: UUID) async throws {
        let predicate = #Predicate<ScanRecord> { $0.id == id }
        let descriptor = FetchDescriptor<ScanRecord>(predicate: predicate)
        guard let record = try context.fetch(descriptor).first else { return }
        context.delete(record)
        try context.save()
    }
}
