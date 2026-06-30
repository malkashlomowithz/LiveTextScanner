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
    @Environment(AppDependencyContainer.self) private var container

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
        .task { await viewModel.startScanning() }
        .onDisappear(perform: viewModel.stopScanning)
        .sheet(
            item: $vm.capturedResult,
            onDismiss: { Task { await viewModel.startScanning() } }
        ) { capture in
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
        TextOverlayView(regions: viewModel.currentRegions)
            .ignoresSafeArea()
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: viewModel.currentRegions)
    }

    private var controlsLayer: some View {
        VStack {
            HStack(alignment: .top) {
                ScanStatusBadge(detectionCount: viewModel.currentRegions.count)
                Spacer()
                NavigationLink(value: AppRoute.settings) {
                    Label("Settings", systemImage: "gear")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .glassCircle()
                }
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.stopScanning()
                })

                NavigationLink(value: AppRoute.history) {
                    Label("History", systemImage: "clock")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .glassCircle()
                }
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.stopScanning()
                })
            }
            Spacer()
            ShutterButton(
                isEnabled: !viewModel.currentRegions.isEmpty,
                action: viewModel.captureCurrentFrame
            )
        }
        .padding()
    }
}

#Preview {
    CameraView(
        viewModel: CameraViewModel(
            liveScanUseCase: LiveScanUseCase(
                frameProvider: MockCameraFrameProvider(),
                recognizer: MockTextRecognizer(),
                deduplicator: SimilarityDeduplicator()
            ),
            captureUseCase: CaptureTextUseCase(repository: InMemoryStore())
        )
    )
}
