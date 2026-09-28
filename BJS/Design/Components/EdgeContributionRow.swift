import SwiftUI

enum EdgeContributionLayout {
    /// The bar's share of its half-width: |change| / scale, clamped to 0...1.
    static func barFraction(change: Double, scale: Double) -> Double {
        guard scale > 0 else { return 0 }
        return min(abs(change) / scale, 1)
    }
}

/// One step of a house-edge breakdown: the rule's label and signed change, above a bar that
/// diverges from a centre zero line. It grows right in `incorrect` when the rule raises the house
/// edge (worse for the player), and left in `correct` when it lowers it. `scale` is the largest
/// |change| on screen, so bars compare within one breakdown. Sits inside a `SettingsSection`.
struct EdgeContributionRow: View {
    let label: String
    let value: String
    let change: Double
    let scale: Double
    let accessibilityText: String

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: FeltSpacing.m) {
                Text(label)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: FeltSpacing.s)
                Text(value)
                    .feltText(.body)
                    .monospacedDigit()
                    .foregroundStyle(FeltColor.textSecondary)
            }
            EdgeContributionBar(fraction: EdgeContributionLayout.barFraction(change: change, scale: scale),
                                raisesEdge: change > 0)
                .frame(height: 6)
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.vertical, FeltSpacing.s)
        .frame(minHeight: FeltTapTarget.minimum)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}

private struct EdgeContributionBar: View {
    let fraction: Double
    let raisesEdge: Bool

    var body: some View {
        GeometryReader { geo in
            let half = geo.size.width / 2
            let length = half * fraction
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(FeltColor.textTertiary.opacity(0.2))
                    .frame(height: 2)
                    .frame(maxHeight: .infinity)
                Rectangle()
                    .fill(FeltColor.textTertiary.opacity(0.6))
                    .frame(width: 1)
                    .offset(x: half - 0.5)
                Capsule()
                    .fill(raisesEdge ? FeltColor.incorrect : FeltColor.correct)
                    .frame(width: length)
                    .offset(x: raisesEdge ? half : half - length)
            }
        }
    }
}
