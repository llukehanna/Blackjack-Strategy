import SwiftUI
import BJSCore

struct HandView: View {
    let cards: [Card]
    var faceDownIndices: Set<Int> = []

    var body: some View {
        if cards.count >= 5 {
            // Overlapping layout for 5+ cards
            ZStack(alignment: .leading) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    CardView(card: card, faceDown: faceDownIndices.contains(index))
                        .offset(x: CGFloat(index) * 32)
                }
            }
            .frame(height: 80)
        } else {
            HStack(spacing: 8) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    CardView(card: card, faceDown: faceDownIndices.contains(index))
                }
            }
        }
    }
}
