//
//  CaptureTextUseCaseTests.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Testing
@testable import LiveTextScanner

@Suite("CaptureTextUseCase")
struct CaptureTextUseCaseTests {

    @Test("Execute saves the full text to the repository")
    @MainActor
    func savesFullText() async throws {
        let store = InMemoryStore()
        let useCase = CaptureTextUseCase(repository: store)
        let capture = ScanCapture.make(text: "Hello World")

        try await useCase.execute(capture)

        let records = try await store.fetchAll()
        #expect(records.count == 1)
        #expect(records[0].text == "Hello World")
    }

    @Test("Execute persists the language tag")
    @MainActor
    func savesLanguageTag() async throws {
        let store = InMemoryStore()
        let useCase = CaptureTextUseCase(repository: store)
        let capture = ScanCapture.make(text: "Bonjour")

        try await useCase.execute(capture, language: "fr")

        let records = try await store.fetchAll()
        #expect(records[0].language == "fr")
    }

    @Test("Execute persists source regions")
    @MainActor
    func savesSourceRegions() async throws {
        let store = InMemoryStore()
        let useCase = CaptureTextUseCase(repository: store)
        let capture = ScanCapture(regions: [
            .make(text: "Line one"),
            .make(text: "Line two")
        ])

        try await useCase.execute(capture)

        let records = try await store.fetchAll()
        #expect(records[0].sourceRegions == ["Line one", "Line two"])
    }

    @Test("Multiple executions each produce a separate record")
    @MainActor
    func multipleExecutionsProduceSeparateRecords() async throws {
        let store = InMemoryStore()
        let useCase = CaptureTextUseCase(repository: store)

        try await useCase.execute(ScanCapture.make(text: "First"))
        try await useCase.execute(ScanCapture.make(text: "Second"))

        let records = try await store.fetchAll()
        #expect(records.count == 2)
    }

    @Test("fullText joins regions with newlines")
    func fullTextJoinsRegionsWithNewlines() {
        let capture = ScanCapture(regions: [
            .make(text: "Line one"),
            .make(text: "Line two"),
            .make(text: "Line three")
        ])

        #expect(capture.fullText == "Line one\nLine two\nLine three")
    }

    @Test("fullText is empty for a capture with no regions")
    func fullTextEmptyForNoRegions() {
        let capture = ScanCapture(regions: [])
        #expect(capture.fullText == "")
    }
}
