//
//  ToastView.swift
//  LiveTextScanner
//
//  Created by Malky on 29/06/2026.
//

import SwiftUI

struct ToastView: View {
    let content: ToastContent

    var body: some View {
        Label(content.message, systemImage: content.systemImage)
            .font(.subheadline.bold())
            .foregroundStyle(Color("SecondaryColor"))
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(Color("PrimaryColor"), in: .capsule)
            .shadow(radius: 8, y: 2)
            .accessibilityElement(children: .combine)
    }
}

#Preview {
    ToastView(content: ToastContent(message: "Copied", systemImage: "checkmark.circle.fill"))
}
