import BJSCore
import SwiftUI

/// A playing card drawn in SwiftUI (spec §4).
///
/// Face: cream, rank + suit index top-left, large suit bottom-right.
/// Back: cream border around diagonal felt stripes.
/// The caller sets the width; height is width × 1.4. Glyph sizes scale with the
/// width, not with Dynamic Type, because the card is a graphic.
/// Changing `isFaceUp` flips the card (0.35 s); under Reduce Motion it cross-fades.
struct PlayingCard: View {
    private let card: Card
    private let isFaceUp: Bool
    private let width: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ card: Card, isFaceUp: Bool = true, width: CGFloat) {
        self.card = card
        self.isFaceUp = isFaceUp
        self.width = width
    }

    private var height: CGFloat { width * FeltMetrics.cardAspectRatio }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: FeltRadius.card, style: .continuous) }
    private var suitColor: Color { CardText.isRed(card.suit) ? FeltColor.suitRed : FeltColor.suitBlack }

    /// Opacity switches at the half-way point of the flip, when the card is edge-on.
    private var opacityAnimation: Animation {
        reduceMotion
            ? FeltMotion.crossFade(duration: FeltMotion.flipDuration)
            : .linear(duration: 0.01).delay(FeltMotion.flipDuration / 2)
    }

    private var faceAngle: Double { reduceMotion || isFaceUp ? 0 : 180 }
    private var backAngle: Double { reduceMotion || !isFaceUp ? 0 : -180 }

    var body: some View {
        ZStack {
            back
                .animation(opacityAnimation) { $0.opacity(isFaceUp ? 0 : 1) }
                .animation(FeltMotion.flip) { $0.rotation3DEffect(.degrees(backAngle), axis: (x: 0, y: 1, z: 0)) }
            face
                .animation(opacityAnimation) { $0.opacity(isFaceUp ? 1 : 0) }
                .animation(FeltMotion.flip) { $0.rotation3DEffect(.degrees(faceAngle), axis: (x: 0, y: 1, z: 0)) }
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFaceUp ? CardText.accessibilityLabel(card) : CardText.faceDownLabel)
    }

    private var face: some View {
        shape
            .fill(FeltColor.cream)
            .overlay(alignment: .topLeading) {
                VStack(spacing: 0) {
                    Text(CardText.rankIndex(card.rank))
                        .font(.system(size: width * 0.30, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Image(systemName: CardText.suitSymbolName(card.suit))
                        .font(.system(size: width * 0.20))
                }
                .padding(width * 0.08)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: CardText.suitSymbolName(card.suit))
                    .font(.system(size: width * 0.45))
                    .padding(width * 0.10)
            }
            .foregroundStyle(suitColor)
    }

    private var back: some View {
        shape
            .fill(FeltColor.cream)
            .overlay {
                DiagonalStripes(spacing: width * 0.12)
                    .stroke(FeltColor.feltLight, lineWidth: width * 0.04)
                    .background(FeltColor.feltBase)
                    .clipShape(RoundedRectangle(cornerRadius: FeltRadius.card / 2, style: .continuous))
                    .padding(width * 0.07)
            }
    }
}

/// Parallel 45° lines filling a rectangle; the card-back pattern.
struct DiagonalStripes: Shape {
    let spacing: CGFloat

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        guard spacing > 0 else { return path }
        var x = rect.minX - rect.height
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += spacing
        }
        return path
    }
}
