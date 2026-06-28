//
//  ScanHistoryUseCaseTests.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Foundation
import Testing
@testable import LiveTextScanner

@Suite("ScanHistoryUseCase")
struct ScanHistoryUseCaseTests {

    // MARK: - Helpers

    @MainActor
    private func makeUseCase(seeded texts: [String] = []) async throws -> (ScanHistoryUseCase, InMemoryStore) {
        let store = InMemoryStore()
        for text in texts {
            try await store.save(text: text, date: .now, language: nil, sourceRegions: [], thumbnailData: nil)
        }
        return (ScanHistoryUseCase(repository: store), store)
    }

    // MARK: - Fetch

    @Test("fetchAll returns every saved record")
    @MainActor
    func fetchAllReturnsAll() async throws {
        let (useCase, _) = try await makeUseCase(seeded: ["Alpha", "Beta", "Gamma"])

        let records = try await useCase.fetchAll()

        #expect(records.count == 3)
    }

    // MARK: - Search

    @Test("Empty query returns all records")
    @MainActor
    func emptyQueryReturnsAll() async throws {
        let (useCase, _) = try await makeUseCase(seeded: ["Hello World", "Foo Bar"])

        let results = try await useCase.search(query: "")

        #expect(results.count == 2)
    }

    @Test("Whitespace-only query returns all records")
    @MainActor
    func whitespaceQueryReturnsAll() async throws {
        let (useCase, _) = try await makeUseCase(seeded: ["Hello World"])

        let results = try await useCase.search(query: "   ")

        #expect(results.count == 1)
    }

    @Test("Search filters by matching text")
    @MainActor
    func searchFiltersResults() async throws {
        let (useCase, _) = try await makeUseCase(seeded: ["Hello World", "Foo Bar", "Hello Again"])

        let results = try await useCase.search(query: "Hello")

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.text.localizedStandardContains("Hello") })
    }

    @Test("Search with no matching text returns empty array")
    @MainActor
    func searchNoMatchReturnsEmpty() async throws {
        let (useCase, _) = try await makeUseCase(seeded: ["Hello World"])

        let results = try await useCase.search(query: "zzznomatch")

        #expect(results.isEmpty)
    }

    // MARK: - Delete

    @Test("Delete removes the correct record")
    @MainActor
    func deleteRemovesRecord() async throws {
        let (useCase, store) = try await makeUseCase(seeded: ["Keep me", "Delete me"])
        let idToDelete = store.records.first(where: { $0.text == "Delete me" })!.id

        try await useCase.delete(id: idToDelete)

        let remaining = try await useCase.fetchAll()
        #expect(remaining.count == 1)
        #expect(remaining[0].text == "Keep me")
    }

    @Test("Delete with unknown ID is a no-op")
    @MainActor
    func deleteUnknownIdIsNoOp() async throws {
        let (useCase, _) = try await makeUseCase(seeded: ["Keep me"])

        try await useCase.delete(id: .init())  // random UUID

        let records = try await useCase.fetchAll()
        #expect(records.count == 1)
    }

    @Test("Delete all records leaves history empty")
    @MainActor
    func deleteAllLeavesEmpty() async throws {
        let (useCase, store) = try await makeUseCase(seeded: ["One", "Two"])

        for record in store.records {
            try await useCase.delete(id: record.id)
        }

        let records = try await useCase.fetchAll()
        #expect(records.isEmpty)
    }
}
