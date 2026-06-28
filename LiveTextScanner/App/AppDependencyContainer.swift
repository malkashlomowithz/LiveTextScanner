//
//  AppDependencyContainer.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftData
import Observation

/// Constructs and owns all app dependencies. Created once at launch and injected via `@Environment`.
@Observable
@MainActor
final class AppDependencyContainer {

    let cameraViewModel: CameraViewModel
    let historyViewModel: HistoryViewModel

    init() {
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
            recognizer: VisionTextRecognizer(),
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
    }
}
