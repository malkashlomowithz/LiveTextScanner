//
//  CameraView.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

struct CameraView: View {
    @State private var viewModel: CameraViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: CameraViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        @Bindable var vm = viewModel

        ZStack {
            cameraBackground
            overlayLayer
            controlsLayer
        }
        .ignoresSafeArea()
        .task { await viewModel.startScanning() }
        .onDisappear(perform: viewModel.stopScanning)
        .sheet(item: $vm.capturedResult) { capture in
            CaptureResultView(
                viewModel: CaptureViewModel(capture: capture),
                onSave: { Task { await viewModel.saveCapture(capture) } }
            )
        }
        .alert("Scan Error", isPresented: $vm.showingError) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var cameraBackground: some View {
        Group {
            if let session = viewModel.previewSession {
                CameraPreviewView(session: session)
            } else {
                Color.black
            }
        }
        .ignoresSafeArea()
    }

    private var overlayLayer: some View {
        TextOverlayView(regions: viewModel.currentCapture?.regions ?? [])
            .ignoresSafeArea()
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: viewModel.currentCapture?.id)
    }

    private var controlsLayer: some View {
        VStack {
            Spacer()
            Button("Capture Text", systemImage: "camera.fill", action: viewModel.captureCurrentFrame)
                .labelStyle(.iconOnly)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.white)
                .padding(24)
                .background(.ultraThinMaterial, in: Circle())
                .padding(.bottom, 48)
        }
    }
}

#Preview {
    CameraView(viewModel: CameraViewModel(
        liveScanUseCase: LiveScanUseCase(
            frameProvider: MockCameraFrameProvider(),
            recognizer: MockTextRecognizer(),
            deduplicator: SimilarityDeduplicator()
        ),
        captureUseCase: CaptureTextUseCase(repository: InMemoryStore())
    ))
}
