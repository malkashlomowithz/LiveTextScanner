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
        HStack(alignment: .top, spacing: 14) {
            numberBadge
            VStack(alignment: .leading, spacing: 8) {
                Text(record.text)
                    .lineLimit(2)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(record.date, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("PrimaryColor").opacity(0.12), lineWidth: 1)
        }
    }

    private var numberBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: "doc.text.viewfinder")
                .font(.title3)
            Text("#\(record.number)")
                .font(.caption2.monospacedDigit().bold())
        }
        .foregroundStyle(Color("SecondaryColor"))
        .frame(width: 54, height: 54)
        .background(Color("PrimaryColor"), in: .rect(cornerRadius: 12))
    }
}
