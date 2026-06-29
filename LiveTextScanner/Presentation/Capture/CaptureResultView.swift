//
//  CaptureResultView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

struct CaptureResultView: View {
    @State private var viewModel: CaptureViewModel
    @State private var toast: ToastContent?
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
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    
                    ShareLink(item: viewModel.capture.fullText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .labelStyle(.iconOnly)
                    
                    Menu {
                        Button("Copy to Clipboard", systemImage: "doc.on.doc") {
                            viewModel.copyToClipboard()
                            toast = ToastContent(
                                message: "Copied to clipboard",
                                systemImage: "doc.on.doc.fill"
                            )
                        }
                        Button("Save to History", systemImage: "square.and.arrow.down") {
                            onSave()
                            toast = ToastContent(
                                message: "Saved to history",
                                systemImage: "checkmark.circle.fill"
                            )
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .toast($toast)
        }
    }
}
