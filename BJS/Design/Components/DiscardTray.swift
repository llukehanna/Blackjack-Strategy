import SwiftUI

enum DiscardTrayLayout {
    /// How full the tray is: decks played over the whole shoe, clamped to 0...1.
    static func fillFraction(decksTotal: Double, decksPlayed: Double) -> Double {
        guard decksTotal > 0 else { return 0 }
        return min(max(decksPlayed / decksTotal, 0), 1)
    }

    /// Heights (fractions from the bottom) of the faint whole-deck ticks, between decks.
    static func tickFractions(decksTotal: Double) -> [Double] {
        let whole = Int(decksTotal.rounded(.down))
        guard whole > 1 else { return [] }
        return (1..<whole).map { Double($0) / decksTotal }
    }

    /// Rounded to the nearest half deck, so VoiceOver users still estimate (Step 4 spec §2).
    static func accessibilityValue(decksPlayed: Double) -> String {
        let halves = (decksPlayed * 2).rounded() / 2
        let number = halves == halves.rounded() ? "\(Int(halves))" : String(format: "%.1f", halves)
        return "About \(number) \(halves == 1 ? "deck" : "decks") played"
    }
}

/// A discard tray: an outline the height of the whole shoe, filled from the bottom with the decks
/// already played as stacked cream card edges. Faint whole-deck ticks and no number: the user
/// estimates decks remaining as they would at a table.
struct DiscardTray: View {
    let decksTotal: Double
    let decksPlayed: Double
    var height: CGFloat = 160

    static let width: CGFloat = 64

    var body: some View {
        let fill = DiscardTrayLayout.fillFraction(decksTotal: decksTotal, decksPlayed: decksPlayed)
        let inner = height - 2 * FeltSpacing.xs
        let shape = RoundedRectangle(cornerRadius: FeltRadius.chip)
        ZStack(alignment: .bottom) {
            shape.fill(FeltColor.surfaceInset)
            StackedEdges(spacing: 3)
                .stroke(FeltColor.onCreamSecondary.opacity(0.5), lineWidth: 0.5)
                .background(FeltColor.cream)
                .frame(height: inner * fill)
                .clipShape(RoundedRectangle(cornerRadius: FeltRadius.chip - FeltSpacing.xs))
                .padding(FeltSpacing.xs)
            ForEach(DiscardTrayLayout.tickFractions(decksTotal: decksTotal), id: \.self) { fraction in
                Rectangle()
                    .fill(FeltColor.textTertiary.opacity(0.6))
                    .frame(width: FeltSpacing.m, height: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: -(FeltSpacing.xs + inner * fraction))
            }
            shape.strokeBorder(FeltColor.textTertiary.opacity(0.6), lineWidth: 1)
        }
        .frame(width: Self.width, height: height)
        .accessibilityElement()
        .accessibilityLabel("Discard tray")
        .accessibilityValue(DiscardTrayLayout.accessibilityValue(decksPlayed: decksPlayed))
    }
}

/// Evenly spaced horizontal lines: the edges of stacked cards. `nonisolated` because SwiftUI draws
/// shapes off the main actor.
nonisolated struct StackedEdges: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y = rect.maxY - spacing
        while y > rect.minY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y -= spacing
        }
        return path
    }
}
