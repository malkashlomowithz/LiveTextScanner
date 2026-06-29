//  HistoryView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @State private var localSearchQuery = ""

    init(viewModel: HistoryViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var filteredRecords: [ScanRecord] {
        if localSearchQuery.isEmpty {
            return viewModel.records
        } else {
            return viewModel.records.filter { record in
                record.text.localizedCaseInsensitiveContains(localSearchQuery)
            }
        }
    }

    var body: some View {
        List {
            if !filteredRecords.isEmpty {
                Section {
                    ForEach(filteredRecords) { record in
                        NavigationLink(value: record) {
                            ScanRowView(record: record)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                viewModel.delete(record)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteRecords)
                } header: {
                    SwipeHintHeader()
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color("SecondaryColor").opacity(0.08))
        .navigationTitle("Scan History")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color("PrimaryColor"))
        .toolbar {
            if !filteredRecords.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
        .searchable(
            text: $localSearchQuery,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search scans"
        )
        .navigationDestination(for: ScanRecord.self) { record in
            ScanDetailView(record: record) {
                viewModel.delete(record)
            }
        }
        .overlay {
            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    "No Scans Yet",
                    systemImage: "doc.text.viewfinder",
                    description: Text("Scanned text will appear here.")
                )
                .foregroundStyle(Color("PrimaryColor"))
            }
        }
        .task {
            await viewModel.loadRecords()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct SwipeHintHeader: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw")
            Text("Swipe a row to delete, or tap Edit")
        }
        .font(.caption)
        .foregroundStyle(Color("PrimaryColor").opacity(0.7))
        .textCase(nil)
        .padding(.vertical, 4)
    }
}
