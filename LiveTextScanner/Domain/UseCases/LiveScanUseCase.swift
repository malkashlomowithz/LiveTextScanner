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

    /// Per-frame stream of currently detected regions (possibly empty).
    /// Drives the live overlay so highlight boxes follow the camera.
    /// Recreated on every `start()` — read it *after* calling `start()`.
    private(set) var liveRegions: AsyncStream<[TextRegion]>
    private var liveRegionsContinuation: AsyncStream<[TextRegion]>.Continuation
    private var producerTask: Task<Void, Never>?

    init(
        frameProvider: some CameraFrameProviderProtocol,
        recognizer: some TextRecognitionProtocol,
        deduplicator: some DeduplicationStrategy
    ) {
        self.frameProvider = frameProvider
        self.recognizer = recognizer
        self.deduplicator = deduplicator
        (self.liveRegions, self.liveRegionsContinuation) = AsyncStream<[TextRegion]>.makeStream()
    }

    /// Starts the camera and returns a stream of stable, deduplicated captures.
    /// Iterate the stream inside a `Task` in the caller; call `stop()` to end scanning.
    /// For the live overlay, iterate `liveRegions` in a separate task.
    func start() async -> AsyncStream<ScanCapture> {
        // Tear down any prior session so a fresh start is fully independent.
        producerTask?.cancel()

        let frames = await frameProvider.start()
        deduplicator.reset()

        // AsyncStream is single-use, so recreate both pipelines per session.
        (liveRegions, liveRegionsContinuation) = AsyncStream<[TextRegion]>.makeStream()
        let (capturesStream, capturesContinuation) = AsyncStream<ScanCapture>.makeStream()

        // Extract locals so the closure captures value-typed copies where possible.
        let recognizer = self.recognizer
        let deduplicator = self.deduplicator
        let liveRegionsContinuation = self.liveRegionsContinuation

        producerTask = Task {
            for await pixelBuffer in frames {
                if Task.isCancelled { break }
                do {
                    let regions = try await recognizer.recognizeText(in: pixelBuffer)
                    // Emit every frame's regions so the overlay tracks the camera —
                    // including empty results, which clear stale highlight boxes.
                    liveRegionsContinuation.yield(regions)
                    guard !regions.isEmpty else { continue }
                    let capture = ScanCapture(regions: regions)
                    if let stable = deduplicator.process(capture) {
                        capturesContinuation.yield(stable)
                    }
                } catch {
                    // Non-fatal — skip frames that fail recognition and keep streaming.
                }
            }
            capturesContinuation.finish()
        }

        return capturesStream
    }

    func stop() {
        // Finishing the frames stream lets the producer drain any buffered
        // frames and exit naturally, which also finishes the captures stream.
        frameProvider.stop()
        liveRegionsContinuation.yield([])
    }
}
