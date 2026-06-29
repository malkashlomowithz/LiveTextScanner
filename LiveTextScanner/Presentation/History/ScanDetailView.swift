//
//  ScanDetailView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

struct ScanDetailView: View {
    let record: ScanRecord
    let onDelete: () -> Void

    @State private var toast: ToastContent?
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            Text(record.text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
        }
        .navigationTitle(Text(record.date, format: .dateTime.day().month().year()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = record.text
                    toast = ToastContent(
                        message: "Copied to clipboard",
                        systemImage: "doc.on.doc.fill"
                    )
                }
                ShareLink(item: record.text)
                Button("Delete", systemImage: "trash", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .tint(.red)
            }
        }
        .confirmationDialog(
            "Delete this scan?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This scan will be permanently removed.")
        }
        .toast($toast)
    }
}
