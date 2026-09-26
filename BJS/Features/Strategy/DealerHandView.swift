import SwiftUI
import BJSCore

/// The dealer's cards: the hole card flips at the outcome; later draws deal in.
struct DealerHandView: View {
    let cards: [Card]
    let isRevealed: Bool
    let total: Int?
    let cardWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let offsets = HandLayout.offsets(count: cards.count, cardWidth: cardWidth, overlap: 0.55)
        VStack(spacing: FeltSpacing.s) {
            ZStack(alignment: .topLeading) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    Group {
                        if index == 1 {
                            FlipCard(card: card, isFaceUp: isRevealed, width: cardWidth)
                        } else {
                            PlayingCard(card: card, width: cardWidth)
                        }
                    }
                    .offset(x: offsets[index])
                    .transition(FeltMotion.dealTransition(reduceMotion: reduceMotion))
                }
            }
            .frame(width: HandLayout.totalWidth(count: cards.count, cardWidth: cardWidth, overlap: 0.55),
                   height: PlayingCardMetrics.height(forWidth: cardWidth), alignment: .topLeading)
            .animation(FeltMotion.deal, value: cards.count)
            Text(total.map { "\($0)" } ?? " ")
                .feltText(.stat).foregroundStyle(FeltColor.textPrimary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Dealer")
    }
}
