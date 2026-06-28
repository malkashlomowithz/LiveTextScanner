//
//  CaptureViewModel.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class CaptureViewModel {
    let capture: ScanCapture

    init(capture: ScanCapture) {
        self.capture = capture
    }

    func copyToClipboard() {
        UIPasteboard.general.string = capture.fullText
    }
}
