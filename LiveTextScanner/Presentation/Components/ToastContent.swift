//
//  ToastContent.swift
//  LiveTextScanner
//
//  Created by Malky on 29/06/2026.
//

import Foundation

/// Lightweight payload that drives the toast overlay.
/// A new `id` ensures the auto-dismiss timer restarts whenever a toast is shown,
/// even if the message text is identical to the previous one.
struct ToastContent: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let systemImage: String
}
