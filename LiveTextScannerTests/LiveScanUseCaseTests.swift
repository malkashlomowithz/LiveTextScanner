//
//  LiveScanUseCaseTests.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import Testing
@testable import LiveTextScanner

@Suite("LiveScanUseCase")
struct LiveScanUseCaseTests {

    // MARK: - Helpers

    private func makeSUT(
        responses: [[TextRegion]] = [],
        stabilityThreshold: Int = 1
    ) -> (LiveScanUseCase, MockCameraFrameProvider) {
        let frameProvider = MockCameraFrameProvider()
        let recognizer = MockTextRecognizer(stubbedResponses: responses)
        let deduplicator = SimilarityDeduplicator(stabilityThreshold: stabilityThreshold)
        let useCase = LiveScanUseCase(
            frameProvider: frameProvider,
            recognizer: recognizer,
            deduplicator: deduplicator
        )
        return (useCase, frameProvider)
    }

    // MARK: - Pipeline

    @Test("Recognized regions are yielded to the capture stream")
    func recognizedRegionsFlowThrough() async {
        let (useCase, frameProvider) = makeSUT(
            responses: [[.make(text: "Hello")]],
            stabilityThreshold: 1
        )

        let stream = await useCase.start()
        frameProvider.emit(makePixelBuffer())
        useCase.stop()

        var captures: [ScanCapture] = []
        for await capture in stream {
            captures.append(capture)
        }

        #expect(captures.count == 1)
        #expect(captures[0].regions[0].text == "Hello")
    }

    @Test("Multiple distinct frames produce multiple stable captures")
    func multipleFramesProduceMultipleCaptures() async {
        let (useCase, frameProvider) = makeSUT(
            responses: [
                [.make(text: "Frame A")],
                [.make(text: "Frame B")]
            ],
            stabilityThreshold: 1
        )

        let stream = await useCase.start()
        frameProvider.emit(makePixelBuffer())
        frameProvider.emit(makePixelBuffer())
        useCase.stop()

        var captures: [ScanCapture] = []
        for await capture in stream {
            captures.append(capture)
        }

        #expect(captures.count == 2)
    }

    @Test("Frames below stability threshold produce no output")
    func belowThresholdProducesNoOutput() async {
        let (useCase, frameProvider) = makeSUT(
            responses: [[.make(text: "Hello")]],
            stabilityThreshold: 3  // needs 3 identical frames
        )

        let stream = await useCase.start()
        frameProvider.emit(makePixelBuffer())  // only 1 frame — not stable
        useCase.stop()

        var captures: [ScanCapture] = []
        for await capture in stream {
            captures.append(capture)
        }

        #expect(captures.isEmpty)
    }

    @Test("Empty recognition result produces no capture")
    func emptyRecognitionProducesNoCapture() async {
        let (useCase, frameProvider) = makeSUT(
            responses: [[]]  // recognizer returns no regions
        )

        let stream = await useCase.start()
        frameProvider.emit(makePixelBuffer())
        useCase.stop()

        var captures: [ScanCapture] = []
        for await capture in stream {
            captures.append(capture)
        }

        #expect(captures.isEmpty)
    }

    // MARK: - Lifecycle

    @Test("Start sets the frame provider to running")
    func startSetsProviderRunning() async {
        let (useCase, frameProvider) = makeSUT()

        _ = await useCase.start()

        #expect(frameProvider.isRunning)
    }

    @Test("Stop sets the frame provider to not running")
    func stopSetsProviderNotRunning() async {
        let (useCase, frameProvider) = makeSUT()

        _ = await useCase.start()
        useCase.stop()

        #expect(!frameProvider.isRunning)
    }
}
