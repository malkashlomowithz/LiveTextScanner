//
//  LanguagePickerView.swift
//  LiveTextScanner
//
//  Created by Malky on 30/06/2026.
//

import SwiftUI

/// Scrollable list of Vision-supported languages the user can toggle on or off.
struct LanguagePickerView: View {
    @Bindable var settings: LanguageSettings

    var body: some View {
        ForEach(settings.availableLanguages, id: \.self) { code in
            LanguageRowView(
                code: code,
                isSelected: settings.selectedLanguages.contains(code),
                onToggle: {
                    if settings.selectedLanguages.contains(code) {
                        settings.selectedLanguages.removeAll { $0 == code }
                    } else {
                        settings.selectedLanguages.append(code)
                    }
                }
            )
        }
    }
}

private struct LanguageRowView: View {
    let code: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(Locale.current.localizedString(forLanguageCode: code) ?? code)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .bold()
                }
            }
        }
        .tint(.primary)
    }
}
