//
//  HistoryViewModel.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Observation
import Foundation

@Observable
@MainActor
final class HistoryViewModel {
    private(set) var records: [ScanRecord] = []
    var searchQuery = ""
    var errorMessage: String?
    var showingError = false

    private let historyUseCase: ScanHistoryUseCase

    init(historyUseCase: ScanHistoryUseCase) {
        self.historyUseCase = historyUseCase
    }

    func loadRecords() async {
        do {
            records = try await historyUseCase.search(query: searchQuery)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    func deleteRecords(at offsets: IndexSet) {
        let ids = offsets.map { records[$0].id }
        Task {
            for id in ids {
                await delete(id: id)
            }
        }
    }

    private func delete(id: UUID) async {
        do {
            try await historyUseCase.delete(id: id)
            records.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
