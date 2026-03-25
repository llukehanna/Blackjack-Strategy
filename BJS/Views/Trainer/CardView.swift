import SwiftUI
import BJSCore

struct CardView: View {
    let card: Card
    let faceDown: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(faceDown ? BJSColors.cardFaceDown : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(Color.secondary, lineWidth: 1)
                )
            if !faceDown {
                Text(cardLabel)
                    .font(Typography.mono)
                    .foregroundStyle(suitColor)
            }
        }
        .frame(width: 56, height: 80)
        .shadow(
            color: Elevation.cardShadowColor,
            radius: Elevation.cardShadowRadius,
            x: 0,
            y: Elevation.cardShadowY
        )
        .accessibilityLabel(faceDown ? "Face down card" : accessibilityDescription)
    }

    // MARK: - Private

    private var rankSymbol: String {
        switch card.rank {
        case .ace: return "A"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        }
    }

    private var suitSymbol: String {
        switch card.suit {
        case .hearts: return "\u{2665}"
        case .diamonds: return "\u{2666}"
        case .clubs: return "\u{2663}"
        case .spades: return "\u{2660}"
        }
    }

    private var suitColor: Color {
        switch card.suit {
        case .hearts, .diamonds: return .red
        case .clubs, .spades: return .primary
        }
    }

    private var cardLabel: String {
        "\(rankSymbol)\(suitSymbol)"
    }

    private var accessibilityDescription: String {
        let rankName: String = switch card.rank {
        case .ace: "Ace"
        case .two: "Two"
        case .three: "Three"
        case .four: "Four"
        case .five: "Five"
        case .six: "Six"
        case .seven: "Seven"
        case .eight: "Eight"
        case .nine: "Nine"
        case .ten: "Ten"
        case .jack: "Jack"
        case .queen: "Queen"
        case .king: "King"
        }
        let suitName: String = switch card.suit {
        case .hearts: "Hearts"
        case .diamonds: "Diamonds"
        case .clubs: "Clubs"
        case .spades: "Spades"
        }
        return "\(rankName) of \(suitName)"
    }
}
