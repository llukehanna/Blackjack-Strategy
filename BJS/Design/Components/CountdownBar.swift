import SwiftUI

enum CountdownProgress {
    static func remainingFraction(startedAt: Date, now: Date, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(startedAt)
        return min(max(1 - elapsed / duration, 0), 1)
    }

    static func isUrgent(startedAt: Date, now: Date, duration: Double) -> Bool {
        duration - now.timeIntervalSince(startedAt) <= 1
    }
}

/// Speed mode's per-decision timer: a thin bar draining from cream, turning `incorrect` in the
/// last second. Under Reduce Motion it updates in half-second steps instead of continuously.
struct CountdownBar: View {
    let startedAt: Date
    let duration: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            TimelineView(.periodic(from: startedAt, by: 0.5)) { context in
                bar(context.date)
            }
        } else {
            TimelineView(.animation) { context in
                bar(context.date)
            }
        }
    }

    private func bar(_ date: Date) -> some View {
        let fraction = CountdownProgress.remainingFraction(startedAt: startedAt, now: date, duration: duration)
        let urgent = CountdownProgress.isUrgent(startedAt: startedAt, now: date, duration: duration)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(FeltColor.surfaceInset)
                Capsule()
                    .fill(urgent ? FeltColor.incorrect : FeltColor.cream)
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel("Time left")
        .accessibilityValue("\(Int((fraction * duration).rounded(.up))) seconds")
    }
}
