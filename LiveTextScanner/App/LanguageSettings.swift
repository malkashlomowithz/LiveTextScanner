//
//  LanguageSettings.swift
//  LiveTextScanner
//
//  Created by Malky on 30/06/2026.
//

import Vision
import Observation

/// Persists and exposes the user's OCR language preferences.
/// `AppDependencyContainer` observes this and pushes changes to the recognizer so every
/// new camera frame picks up the latest configuration without restarting the scan session.
@Observable
@MainActor
final class LanguageSettings {

    /// When `true`, Vision automatically selects the best language model per frame.
    /// Setting this to `false` activates `selectedLanguages` instead.
    var autoDetect: Bool {
        didSet { UserDefaults.standard.set(autoDetect, forKey: Keys.autoDetect) }
    }

    /// BCP-47 codes the user has chosen. Only applied when `autoDetect` is `false`.
    var selectedLanguages: [String] {
        didSet { UserDefaults.standard.set(selectedLanguages, forKey: Keys.selectedLanguages) }
    }

    /// All languages Vision supports for text recognition on this device.
    /// Populated lazily by `loadAvailableLanguages()`.
    private(set) var availableLanguages: [String] = []

    init() {
        autoDetect = UserDefaults.standard.object(forKey: Keys.autoDetect) as? Bool ?? true
        selectedLanguages = UserDefaults.standard.stringArray(forKey: Keys.selectedLanguages) ?? []
    }

    /// BCP-47 codes to hand to the recognizer. Empty array means Vision auto-selects.
    var activeLanguages: [String] {
        autoDetect ? [] : selectedLanguages
    }

    /// Populates `availableLanguages` from Vision's supported recognition language list.
    /// Safe to call repeatedly — skips the query once the list is loaded.
    func loadAvailableLanguages() {
        guard availableLanguages.isEmpty else { return }
        let request = VNRecognizeTextRequest()
        availableLanguages = ((try? request.supportedRecognitionLanguages()) ?? []).sorted()
    }

    private enum Keys {
        static let autoDetect = "ls.autoDetect"
        static let selectedLanguages = "ls.selectedLanguages"
    }
}
