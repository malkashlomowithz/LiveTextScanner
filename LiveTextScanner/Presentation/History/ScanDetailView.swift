//
//  ScanDetailView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

struct ScanDetailView: View {
    let record: ScanRecord

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
                }
                ShareLink(item: record.text)
            }
        }
    }
}
