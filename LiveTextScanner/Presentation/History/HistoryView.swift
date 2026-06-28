//
//  HistoryView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

struct HistoryView: View {
    @State private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            List {
                ForEach(viewModel.records) { record in
                    NavigationLink(value: record) {
                        ScanRowView(record: record)
                    }
                }
                .onDelete(perform: viewModel.deleteRecords)
            }
            .navigationTitle("Scan History")
            .searchable(text: $vm.searchQuery, prompt: "Search scans")
            .navigationDestination(for: ScanRecord.self) { record in
                ScanDetailView(record: record)
            }
            .overlay {
                if viewModel.records.isEmpty {
                    ContentUnavailableView(
                        "No Scans Yet",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Scanned text will appear here.")
                    )
                }
            }
            .task { await viewModel.loadRecords() }
            .onChange(of: viewModel.searchQuery) {
                Task { await viewModel.loadRecords() }
            }
            .alert("Error", isPresented: $vm.showingError) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }
}
