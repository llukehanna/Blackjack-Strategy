import SwiftUI
import BJSCore

/// Overlap ratios for overlapping hand layouts.
/// Raw value is the fraction of `cardWidth` to subtract from HStack spacing.
enum HandOverlap: CGFloat {
    case dealer = 0.30
    case player = 0.45
}

struct HandView: View {
    let cards: [Card]
    var faceDownIndices: Set<Int> = []
    let overlap: HandOverlap

    /// Default card width per UI-SPEC (88pt).
    private let cardWidth: CGFloat = 88

    var body: some View {
        HStack(spacing: -cardWidth * overlap.rawValue) {
            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                if faceDownIndices.contains(index) {
                    CardView(faceDown: true, width: cardWidth)
                } else {
                    CardView(card: card, width: cardWidth)
                }
            }
        }
        // NOTE: do NOT clip this HStack — negative spacing relies on overflow so
        // adjacent cards can visually overlap (07-RESEARCH Pitfall 4).
    }
}
