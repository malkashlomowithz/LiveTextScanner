//
//  SettingsView.swift
//  LiveTextScanner
//
//  Created by Malky on 30/06/2026.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: LanguageSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Auto-detect language", isOn: $settings.autoDetect)
                } footer: {
                    Text("Vision picks the best language model per frame automatically. Disable this to restrict recognition to specific languages.")
                }

                if !settings.autoDetect {
                    Section {
                        if settings.availableLanguages.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color.clear)
                        } else {
                            LanguagePickerView(settings: settings)
                        }
                    } header: {
                        Text("Active Languages")
                    } footer: {
                        if !settings.autoDetect && settings.selectedLanguages.isEmpty {
                            Text("No languages selected — Vision will fall back to English.")
                        }
                    }
                }
            }
            .navigationTitle("Language Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                settings.loadAvailableLanguages()
            }
        }
    }
}

#Preview {
    SettingsView(settings: LanguageSettings())
}
