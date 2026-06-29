//
//  AVCameraSession.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import AVFoundation
import CoreVideo

/// Drives the device camera and exposes frames as an `AsyncStream`.
/// Implemented as an actor so all AVCaptureSession state is protected from data races.
actor AVCameraSession: CameraFrameProviderProtocol {

    /// Exposed for the camera preview layer only. All configuration happens within actor isolation.
    nonisolated let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let captureDelegate = FrameCaptureDelegate()
    private var hasConfigured = false

    init() {}

    func start() async -> AsyncStream<CVPixelBuffer> {
        if !hasConfigured {
            configure()
            hasConfigured = true
        }

        // A fresh stream is created on every start so the consumer always
        // receives a usable AsyncSequence — AsyncStream is single-use.
        let (stream, continuation) = AsyncStream<CVPixelBuffer>.makeStream()
        captureDelegate.continuation = continuation

        if !captureSession.isRunning {
            // startRunning() blocks briefly. Safe here because AVCameraSession
            // is not @MainActor, so it does not freeze the UI.
            captureSession.startRunning()
        }
        return stream
    }

    func stop() {
        captureSession.stopRunning()
        captureDelegate.continuation?.finish()
        captureDelegate.continuation = nil
    }

    // MARK: - Private

    private func configure() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else {
            captureSession.commitConfiguration()
            return
        }

        captureSession.addInput(input)

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        // GCD queue required by AVFoundation's delegate API — frames are immediately
        // bridged to AsyncStream so all downstream processing uses Swift Concurrency.
        videoOutput.setSampleBufferDelegate(
            captureDelegate,
            queue: DispatchQueue(label: "com.livetextscanner.camera.frames", qos: .userInitiated)
        )

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Rotate delivered frames to portrait so Vision's coordinate space matches
        // the display orientation. Without this, Vision x-coordinates map to the
        // landscape frame's left→right axis, which becomes top→bottom on screen —
        // causing bounding boxes to appear as vertical strips instead of text boxes.
        if let connection = videoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }

        captureSession.commitConfiguration()
    }
}

// MARK: - Frame Capture Delegate

private final class FrameCaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    var continuation: AsyncStream<CVPixelBuffer>.Continuation?

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        continuation?.yield(pixelBuffer)
    }
}
