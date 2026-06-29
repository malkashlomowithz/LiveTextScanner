//
//  ScanRowView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

struct ScanRowView: View {
    let record: ScanRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("#\(record.number)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(record.date, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(record.text)
                .lineLimit(2)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}
