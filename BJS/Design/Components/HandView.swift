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

    /// Card slots. A hand that has not busted holds at most 21 cards (twenty-one aces), so 22
    /// slots cover every hand, bust or not.
    static let maxCards = 22

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            // Built eagerly in fixed slots, not with ForEach: SwiftUI can call a ForEach item
            // closure off the main thread while measuring (e.g. under ViewThatFits), which traps
            // Swift 6's main-actor isolation check (crash seen in CI on "Next hand").
            HStack(spacing: -cardWidth * overlap) {
                Group {
                    slot(0); slot(1); slot(2); slot(3); slot(4); slot(5); slot(6); slot(7)
                    slot(8); slot(9); slot(10); slot(11); slot(12); slot(13); slot(14); slot(15)
                    slot(16); slot(17); slot(18); slot(19); slot(20); slot(21)
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

    @ViewBuilder
    private func slot(_ index: Int) -> some View {
        if index < cards.count {
            PlayingCard(cards[index], isFaceUp: !faceDownIndices.contains(index), width: cardWidth)
                .transition(FeltMotion.dealTransition(reduceMotion: reduceMotion))
        }
    }
}
