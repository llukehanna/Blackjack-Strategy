import SwiftUI
import BJSCore

/// A card that reveals itself: a 3D flip over `FeltMotion.flip`, or a cross-fade under Reduce Motion.
struct FlipCard: View {
    let card: Card
    let isFaceUp: Bool
    let width: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch FeltMotion.revealStyle(reduceMotion: reduceMotion) {
            case .crossFade:
                ZStack {
                    PlayingCard(card: card, isFaceUp: false, width: width).opacity(isFaceUp ? 0 : 1)
                    PlayingCard(card: card, isFaceUp: true, width: width).opacity(isFaceUp ? 1 : 0)
                }
                .animation(FeltMotion.ui, value: isFaceUp)
            case .flip:
                ZStack {
                    PlayingCard(card: card, isFaceUp: false, width: width)
                        .rotation3DEffect(.degrees(isFaceUp ? -180 : 0), axis: (x: 0, y: 1, z: 0))
                        .opacity(isFaceUp ? 0 : 1)
                    PlayingCard(card: card, isFaceUp: true, width: width)
                        .rotation3DEffect(.degrees(isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                        .opacity(isFaceUp ? 1 : 0)
                }
                .animation(FeltMotion.flip, value: isFaceUp)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(PlayingCard.accessibilityText(card: card, isFaceUp: isFaceUp))
    }
}
