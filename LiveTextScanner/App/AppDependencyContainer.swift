//
//  AppDependencyContainer.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftData
import Observation
import Foundation

/// Constructs and owns all app dependencies. Created once at launch and injected via `@Environment`.
@Observable
@MainActor
final class AppDependencyContainer {

    let cameraViewModel: CameraViewModel
    let historyViewModel: HistoryViewModel
    let languageSettings: LanguageSettings

    /// Retained so `trackLanguageSettings()` can push preference changes to it indefinitely.
    private let recognizer: VisionTextRecognizer

    init() {
        let recognizer = VisionTextRecognizer()

        if Self.isUITesting {
            // Reset persisted prefs BEFORE creating LanguageSettings so each test run
            // starts from a known baseline — otherwise prior runs leak through init().
            UserDefaults.standard.removeObject(forKey: "ls.autoDetect")
            UserDefaults.standard.removeObject(forKey: "ls.selectedLanguages")
        }

        let settings = LanguageSettings()

        if Self.isUITesting {
            let store = InMemoryStore()
            if ProcessInfo.processInfo.arguments.contains("--seed-history") {
                store.seedForUITesting()
            }
            let liveScanUseCase = LiveScanUseCase(
                frameProvider: MockCameraFrameProvider(),
                recognizer: MockTextRecognizer(),
                deduplicator: SimilarityDeduplicator()
            )
            cameraViewModel = CameraViewModel(
                liveScanUseCase: liveScanUseCase,
                captureUseCase: CaptureTextUseCase(repository: store),
                previewSession: nil
            )
            historyViewModel = HistoryViewModel(
                historyUseCase: ScanHistoryUseCase(repository: store)
            )
            languageSettings = settings
            self.recognizer = recognizer
            trackLanguageSettings()
            return
        }

        let modelContainer: ModelContainer
        do {
            modelContainer = try SwiftDataStore.makeContainer()
        } catch {
            fatalError("SwiftData container could not be created: \(error)")
        }

        let context = ModelContext(modelContainer)
        let repository = ScanRepository(context: context)
        let cameraSession = AVCameraSession()

        let liveScanUseCase = LiveScanUseCase(
            frameProvider: cameraSession,
            recognizer: recognizer,
            deduplicator: SimilarityDeduplicator()
        )

        cameraViewModel = CameraViewModel(
            liveScanUseCase: liveScanUseCase,
            captureUseCase: CaptureTextUseCase(repository: repository),
            previewSession: cameraSession.captureSession
        )
        historyViewModel = HistoryViewModel(
            historyUseCase: ScanHistoryUseCase(repository: repository)
        )
        languageSettings = settings
        self.recognizer = recognizer

        // Seed with current preferences and keep the recognizer in sync as settings change.
        trackLanguageSettings()
    }

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    /// Pushes `languageSettings.activeLanguages` to the recognizer, then re-arms itself so
    /// the next change to either `autoDetect` or `selectedLanguages` triggers another push.
    private func trackLanguageSettings() {
        withObservationTracking {
            recognizer.recognitionLanguages = languageSettings.activeLanguages
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.trackLanguageSettings()
            }
        }
    }
}
