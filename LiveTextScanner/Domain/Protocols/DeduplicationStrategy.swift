//
//  DeduplicationStrategy.swift
//  DeduplicationStrategy
//
//  Created by Malky on 28/06/2026.
//

/// Stateful deduplication processor for a single live scan session.
/// Create a fresh instance each time a scan session begins.
protocol DeduplicationStrategy: AnyObject {
    /// Feed a new frame's capture into the processor.
    /// Returns a stable, deduplicated result once enough consistent frames have been seen,
    /// or nil while still accumulating evidence.
    func process(_ capture: ScanCapture) -> ScanCapture?

    /// Clear internal state. Call when the user moves to new content.
    func reset()
}
