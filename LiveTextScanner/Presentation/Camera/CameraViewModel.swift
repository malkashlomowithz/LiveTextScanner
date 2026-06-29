//
//  CameraViewModel.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import AVFoundation
import Observation

@Observable
@MainActor
final class CameraViewModel {

    /// Per-frame detected regions used for the live overlay.
    var currentRegions: [TextRegion] = []
    /// Latest stable, deduplicated capture used as the snapshot the user can save.
    var currentCapture: ScanCapture?
    var capturedResult: ScanCapture?
    var errorMessage: String?
    var showingError = false

    /// The underlying capture session, used only by `CameraPreviewView` to display the live feed.
    let previewSession: AVCaptureSession?

    private let liveScanUseCase: LiveScanUseCase
    private let captureUseCase: CaptureTextUseCase
    private var scanTask: Task<Void, Never>?
    private var liveRegionsTask: Task<Void, Never>?

    init(
        liveScanUseCase: LiveScanUseCase,
        captureUseCase: CaptureTextUseCase,
        previewSession: AVCaptureSession? = nil
    ) {
        self.liveScanUseCase = liveScanUseCase
        self.captureUseCase = captureUseCase
        self.previewSession = previewSession
    }

    func startScanning() async {
        let liveRegions = liveScanUseCase.liveRegions
        liveRegionsTask = Task { [weak self] in
            for await regions in liveRegions {
                self?.currentRegions = regions
            }
        }

        let stream = await liveScanUseCase.start()
        scanTask = Task { [weak self] in
            for await capture in stream {
                self?.currentCapture = capture
            }
        }
    }

    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
        liveRegionsTask?.cancel()
        liveRegionsTask = nil
        liveScanUseCase.stop()
        currentRegions = []
    }

    func captureCurrentFrame() {
        guard !currentRegions.isEmpty else { return }
        capturedResult = ScanCapture(regions: currentRegions)
    }

    func saveCapture(_ capture: ScanCapture) async {
        do {
            try await captureUseCase.execute(capture)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
