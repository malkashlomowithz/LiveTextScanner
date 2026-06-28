//
//  TestHelpers.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import CoreGraphics
import CoreVideo
@testable import LiveTextScanner

// MARK: - TextRegion factory

extension TextRegion {
    static func make(text: String, boundingBox: CGRect = CGRect(x: 0, y: 0, width: 0.5, height: 0.1)) -> TextRegion {
        TextRegion(text: text, boundingBox: boundingBox)
    }
}

// MARK: - ScanCapture factory

extension ScanCapture {
    static func make(text: String) -> ScanCapture {
        ScanCapture(regions: [.make(text: text)])
    }
}

// MARK: - CVPixelBuffer factory

func makePixelBuffer() -> CVPixelBuffer {
    var buffer: CVPixelBuffer?
    CVPixelBufferCreate(kCFAllocatorDefault, 1, 1, kCVPixelFormatType_32BGRA, nil, &buffer)
    // Failure here would be a programming error in test setup
    guard let buffer else { fatalError("Failed to create test CVPixelBuffer") }
    return buffer
}
