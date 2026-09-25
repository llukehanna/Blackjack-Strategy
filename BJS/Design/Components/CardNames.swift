import BJSCore

extension Rank {
    /// The corner index: "A", "K", "Q", "J", "10" … "2".
    var indexLabel: String {
        switch self {
        case .ace: return "A"
        case .king: return "K"
        case .queen: return "Q"
        case .jack: return "J"
        default: return String(rawValue)
        }
    }

    var spokenName: String {
        switch self {
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
}

extension Suit {
    var symbolName: String {
        switch self {
        case .hearts: return "suit.heart.fill"
        case .diamonds: return "suit.diamond.fill"
        case .clubs: return "suit.club.fill"
        case .spades: return "suit.spade.fill"
        }
    }

    var spokenName: String { rawValue }

    var isRed: Bool { self == .hearts || self == .diamonds }
}

extension Card {
    /// VoiceOver name, e.g. "Eight of clubs".
    var spokenName: String { "\(rank.spokenName) of \(suit.spokenName)" }
}
