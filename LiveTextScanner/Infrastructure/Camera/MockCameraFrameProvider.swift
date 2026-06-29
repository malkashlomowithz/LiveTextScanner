//
//  MockCameraFrameProvider.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

#if DEBUG
import CoreVideo

/// Test double for `CameraFrameProviderProtocol`.
/// Emits pixel buffers on demand so unit tests and SwiftUI Previews run without camera hardware.
final class MockCameraFrameProvider: CameraFrameProviderProtocol, @unchecked Sendable {

    private(set) var isRunning = false
    private var continuation: AsyncStream<CVPixelBuffer>.Continuation?

    init() {}

    func start() async -> AsyncStream<CVPixelBuffer> {
        let (stream, continuation) = AsyncStream<CVPixelBuffer>.makeStream()
        self.continuation = continuation
        isRunning = true
        return stream
    }

    func stop() {
        isRunning = false
        continuation?.finish()
        continuation = nil
    }

    /// Push a synthetic pixel buffer into the stream, simulating a camera frame arriving.
    func emit(_ pixelBuffer: CVPixelBuffer) {
        continuation?.yield(pixelBuffer)
    }
}
#endif
