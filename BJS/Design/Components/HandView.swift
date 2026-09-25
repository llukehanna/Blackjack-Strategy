import SwiftUI
import BJSCore

/// Horizontal positions for overlapping cards. `overlap` is the hidden fraction of each card (0 = side by side).
enum HandLayout {
    static func offsets(count: Int, cardWidth: CGFloat, overlap: CGFloat) -> [CGFloat] {
        (0..<max(count, 0)).map { CGFloat($0) * cardWidth * (1 - overlap) }
    }

    static func totalWidth(count: Int, cardWidth: CGFloat, overlap: CGFloat) -> CGFloat {
        count <= 0 ? 0 : cardWidth + CGFloat(count - 1) * cardWidth * (1 - overlap)
    }
}

/// Overlapping cards with an optional total label beneath.
struct HandView: View {
    let cards: [Card]
    var faceDownIndices: Set<Int> = []
    let cardWidth: CGFloat
    var overlap: CGFloat = 0.55
    var totalLabel: String? = nil

    var body: some View {
        let offsets = HandLayout.offsets(count: cards.count, cardWidth: cardWidth, overlap: overlap)
        VStack(spacing: FeltSpacing.s) {
            ZStack(alignment: .topLeading) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    PlayingCard(card: card, isFaceUp: !faceDownIndices.contains(index), width: cardWidth)
                        .offset(x: offsets[index])
                }
            }
            .frame(width: HandLayout.totalWidth(count: cards.count, cardWidth: cardWidth, overlap: overlap),
                   height: PlayingCardMetrics.height(forWidth: cardWidth),
                   alignment: .topLeading)
            if let totalLabel {
                Text(totalLabel)
                    .feltText(.stat)
                    .foregroundStyle(FeltColor.textPrimary)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
