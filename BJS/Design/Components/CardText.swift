import BJSCore

/// Text and symbols for drawing and announcing a card.
enum CardText {
    static let faceDownLabel = "Face-down card"

    /// The corner index: "A", "2" … "10", "J", "Q", "K".
    static func rankIndex(_ rank: Rank) -> String {
        switch rank {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return String(rank.rawValue)
        }
    }

    static func rankName(_ rank: Rank) -> String {
        switch rank {
        case .two: return "Two"
        case .three: return "Three"
        case .four: return "Four"
        case .five: return "Five"
        case .six: return "Six"
        case .seven: return "Seven"
        case .eight: return "Eight"
        case .nine: return "Nine"
        case .ten: return "Ten"
        case .jack: return "Jack"
        case .queen: return "Queen"
        case .king: return "King"
        case .ace: return "Ace"
        }
    }

    /// VoiceOver label, e.g. "Eight of clubs".
    static func accessibilityLabel(_ card: Card) -> String {
        "\(rankName(card.rank)) of \(card.suit.rawValue)"
    }

    static func isRed(_ suit: Suit) -> Bool {
        suit == .hearts || suit == .diamonds
    }

    /// SF Symbol for the suit.
    static func suitSymbolName(_ suit: Suit) -> String {
        switch suit {
        case .hearts: return "suit.heart.fill"
        case .diamonds: return "suit.diamond.fill"
        case .clubs: return "suit.club.fill"
        case .spades: return "suit.spade.fill"
        }
    }
}
