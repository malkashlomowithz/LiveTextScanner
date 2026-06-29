//
//  CameraFrameProviderProtocol.swift
//  CameraFrameProviderProtocol
//
//  Created by Malky on 28/06/2026.
//

import CoreVideo

/// Abstraction over the camera hardware.
/// Conform to this protocol to supply real AVFoundation frames or synthetic mock frames for testing.
protocol CameraFrameProviderProtocol: AnyObject, Sendable {
    /// Starts capture and returns a fresh stream of pixel buffers for this session.
    /// Each `start()` returns a new stream; `stop()` terminates it.
    func start() async -> AsyncStream<CVPixelBuffer>
    func stop()
}
