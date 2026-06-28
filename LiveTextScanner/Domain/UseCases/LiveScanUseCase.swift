//
//  LiveScanUseCase.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Foundation

/// Orchestrates the live scan pipeline: camera frames → OCR → deduplication → stable captures.
final class LiveScanUseCase {
    private let frameProvider: any CameraFrameProviderProtocol
    private let recognizer: any TextRecognitionProtocol
    private let deduplicator: any DeduplicationStrategy

    init(
        frameProvider: some CameraFrameProviderProtocol,
        recognizer: some TextRecognitionProtocol,
        deduplicator: some DeduplicationStrategy
    ) {
        self.frameProvider = frameProvider
        self.recognizer = recognizer
        self.deduplicator = deduplicator
    }

    /// Starts the camera and returns a stream of stable, deduplicated captures.
    /// Iterate the stream inside a `Task` in the caller; cancel that task to stop scanning.
    func start() async -> AsyncStream<ScanCapture> {
        await frameProvider.start()
        deduplicator.reset()

        // Extract locals so the closure captures value-typed copies where possible.
        let recognizer = self.recognizer
        let deduplicator = self.deduplicator
        let frames = frameProvider.frames

        return AsyncStream { continuation in
            Task {
                for await pixelBuffer in frames {
                    guard !Task.isCancelled else {
                        continuation.finish()
                        return
                    }
                    do {
                        let regions = try await recognizer.recognizeText(in: pixelBuffer)
                        guard !regions.isEmpty else { continue }
                        let capture = ScanCapture(regions: regions)
                        if let stable = deduplicator.process(capture) {
                            continuation.yield(stable)
                        }
                    } catch {
                        // Non-fatal — skip frames that fail recognition and keep streaming.
                    }
                }
                continuation.finish()
            }
        }
    }

    func stop() {
        frameProvider.stop()
    }
}
