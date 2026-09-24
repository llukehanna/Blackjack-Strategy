import BJSCore
import SwiftUI

/// A row of overlapping cards with an optional total label (spec §4).
///
/// `overlap` is the fraction of each card's width covered by the next card (0 = side by side).
/// New cards animate in with the 0.25 s deal motion; under Reduce Motion they fade in.
struct HandView: View {
    private let cards: [Card]
    private let faceDownIndices: Set<Int>
    private let cardWidth: CGFloat
    private let overlap: CGFloat
    private let totalLabel: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(cards: [Card], faceDownIndices: Set<Int> = [], cardWidth: CGFloat, overlap: CGFloat, totalLabel: String? = nil) {
        self.cards = cards
        self.faceDownIndices = faceDownIndices
        self.cardWidth = cardWidth
        self.overlap = min(max(overlap, 0), 0.9)
        self.totalLabel = totalLabel
    }

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            HStack(spacing: -cardWidth * overlap) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    PlayingCard(card, isFaceUp: !faceDownIndices.contains(index), width: cardWidth)
                        .transition(FeltMotion.dealTransition(reduceMotion: reduceMotion))
                }
            }
            .animation(reduceMotion ? FeltMotion.crossFade(duration: FeltMotion.dealDuration) : FeltMotion.deal,
                       value: cards.count)

            if let totalLabel {
                Text(totalLabel)
                    .feltType(.stat)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityLabel("Total \(totalLabel)")
            }
        }
        .accessibilityElement(children: .contain)
    }
}
