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
    /// Continuous stream of pixel buffers, one per captured frame.
    var frames: AsyncStream<CVPixelBuffer> { get }

    func start() async
    func stop()
}
