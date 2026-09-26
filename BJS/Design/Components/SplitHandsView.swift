import SwiftUI
import BJSCore

enum SplitHandsLayout {
    static let maxCardWidth: CGFloat = 76
    static let minCardWidth: CGFloat = 30
    static let overlap: CGFloat = 0.55

    /// The widest card that fits `handCount` hands of `cardsPerHand` overlapping cards side by side.
    static func cardWidth(handCount: Int, cardsPerHand: Int, availableWidth: CGFloat) -> CGFloat {
        let count = CGFloat(max(handCount, 1))
        let perHand = (availableWidth - (count - 1) * FeltSpacing.m) / count
        let factor = 1 + CGFloat(max(cardsPerHand, 1) - 1) * (1 - overlap)
        return min(maxCardWidth, max(minCardWidth, perHand / factor))
    }
}

/// One to four player hands side by side. After a split the active hand carries a brass underline.
struct SplitHandsView: View {
    let hands: [[Card]]
    let totals: [String]
    let activeIndex: Int?
    let availableWidth: CGFloat

    var body: some View {
        let cardsPerHand = max(3, hands.map { $0.count }.max() ?? 0)
        let width = SplitHandsLayout.cardWidth(handCount: hands.count, cardsPerHand: cardsPerHand,
                                               availableWidth: availableWidth)
        HStack(alignment: .top, spacing: FeltSpacing.m) {
            ForEach(Array(hands.enumerated()), id: \.offset) { index, cards in
                let isActive = hands.count > 1 && index == activeIndex
                VStack(spacing: FeltSpacing.s) {
                    HandView(cards: cards, cardWidth: width, overlap: SplitHandsLayout.overlap,
                             totalLabel: index < totals.count ? totals[index] : nil)
                    Capsule()
                        .fill(isActive ? FeltColor.brass : .clear)
                        .frame(height: 3)
                }
                .fixedSize()
                .accessibilityElement(children: .contain)
                .accessibilityLabel(hands.count > 1 ? "Hand \(index + 1) of \(hands.count)" : "Your hand")
                .accessibilityValue(isActive ? "Active" : "")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
