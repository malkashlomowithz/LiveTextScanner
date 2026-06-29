//
//  ShutterButton.swift
//  LiveTextScanner
//
//  Created by Malky on 28/06/2026.
//

import SwiftUI

/// Camera-app-style shutter: white outer ring with a filled inner disk.
/// Scales down on press for tactile feedback and dims when disabled.
struct ShutterButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                Circle()
                    .fill(isEnabled ? Color("SecondaryColor") : .white)
                    .padding(6)
                Image(systemName: "text.viewfinder")
                    .font(.title2.bold())
                    .foregroundStyle(Color("PrimaryColor"))
            }
            .frame(width: 76, height: 76)
            .accessibilityLabel("Capture text")
        }
        .buttonStyle(.shutter)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

private struct ShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ShutterButtonStyle {
    fileprivate static var shutter: ShutterButtonStyle { ShutterButtonStyle() }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 40) {
            ShutterButton(isEnabled: true, action: {})
            ShutterButton(isEnabled: false, action: {})
        }
    }
    .ignoresSafeArea()
}
