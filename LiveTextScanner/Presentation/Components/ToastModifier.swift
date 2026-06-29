//
//  ToastModifier.swift
//  LiveTextScanner
//
//  Created by Malky on 29/06/2026.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastContent?
    var duration: Duration = .seconds(2)

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(content: toast)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: toast.id) {
                            try? await Task.sleep(for: duration)
                            withAnimation(.easeInOut) {
                                self.toast = nil
                            }
                        }
                }
            }
            .animation(.spring(duration: 0.35), value: toast?.id)
    }
}

extension View {
    func toast(_ toast: Binding<ToastContent?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
