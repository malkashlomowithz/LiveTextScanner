//
//  CameraPreviewView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import AVFoundation
import SwiftUI

/// Wraps `AVCaptureVideoPreviewLayer` in a SwiftUI view.
/// UIViewRepresentable is required here because SwiftUI has no native camera preview.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) { }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
