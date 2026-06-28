//
//  CaptureResultView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

struct CaptureResultView: View {
    @State private var viewModel: CaptureViewModel
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CaptureViewModel, onSave: @escaping () -> Void) {
        _viewModel = State(wrappedValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(viewModel.capture.fullText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("Captured Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Copy", systemImage: "doc.on.doc", action: viewModel.copyToClipboard)
                    ShareLink(item: viewModel.capture.fullText)
                    Button("Save", systemImage: "square.and.arrow.down") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}
