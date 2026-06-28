//
//  SwiftDataStore.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftData

/// Factory for the app's SwiftData `ModelContainer`.
enum SwiftDataStore {
    /// Creates a persistent container stored on disk.
    static func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: ScanRecord.self)
    }

    /// Creates an in-memory container — useful for SwiftUI Previews.
    static func makePreviewContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: ScanRecord.self, configurations: config)
    }
}
