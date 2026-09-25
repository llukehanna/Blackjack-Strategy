import SwiftUI
import BJSCore

enum PlayingCardMetrics {
    static let aspectRatio: CGFloat = 1.4

    static func height(forWidth width: CGFloat) -> CGFloat { width * aspectRatio }
}

/// A card drawn in SwiftUI: rank + suit index top-left, large suit bottom-right, cream face.
/// The back is a cream border around diagonal felt stripes.
struct PlayingCard: View {
    let card: Card
    var isFaceUp: Bool = true
    let width: CGFloat

    static func accessibilityText(card: Card, isFaceUp: Bool) -> String {
        isFaceUp ? card.spokenName : "Face-down card"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FeltRadius.card)
                .fill(FeltColor.cream)
            if isFaceUp { face } else { back }
        }
        .frame(width: width, height: PlayingCardMetrics.height(forWidth: width))
        .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
        .accessibilityElement()
        .accessibilityLabel(Self.accessibilityText(card: card, isFaceUp: isFaceUp))
    }

    private var face: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                Text(card.rank.indexLabel)
                    .font(.system(size: width * 0.3, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Image(systemName: card.suit.symbolName)
                    .font(.system(size: width * 0.2))
            }
            .padding(width * 0.08)
            Image(systemName: card.suit.symbolName)
                .font(.system(size: width * 0.42))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(width * 0.1)
        }
        .foregroundStyle(card.suit.isRed ? FeltColor.suitRed : FeltColor.suitBlack)
    }

    private var back: some View {
        let inner = RoundedRectangle(cornerRadius: max(FeltRadius.card - 3, 2))
        return inner
            .fill(FeltColor.feltBase)
            .overlay(DiagonalStripes(spacing: width * 0.12)
                .stroke(FeltColor.feltLight, lineWidth: width * 0.03))
            .clipShape(inner)
            .padding(width * 0.07)
    }
}

/// Parallel 45° lines filling a rectangle.
struct DiagonalStripes: Shape {
    var spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = max(spacing, 2)
        var x = rect.minX - rect.height
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += step
        }
        return path
    }
}
