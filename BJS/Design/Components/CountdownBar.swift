import Foundation
import SwiftUI

/// Speed-mode countdown (added in Step 3, built only from existing Felt tokens):
/// a cream bar on a `surfaceInset` track that empties from right to left.
///
/// The caller drives it, e.g. from a `TimelineView`, with `remainingFraction(...)`.
struct CountdownBar: View {
    private let fraction: Double

    /// `fraction` of time left, 0...1 (clamped).
    init(fraction: Double) {
        self.fraction = min(max(fraction, 0), 1)
    }

    /// Time left as a fraction: 1 at `startedAt`, 0 once `duration` has passed.
    static func remainingFraction(startedAt: Date, now: Date, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        let left = 1 - now.timeIntervalSince(startedAt) / duration
        return min(max(left, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(FeltColor.surfaceInset)
                Capsule(style: .continuous)
                    .fill(FeltColor.cream)
                    .frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: FeltSpacing.s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Time left")
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}
