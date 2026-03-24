/// Represents the four standard playing card suits.
public enum Suit: String, CaseIterable, Sendable, Codable, Hashable {
    case hearts, diamonds, clubs, spades
}

/// Represents the thirteen standard playing card ranks.
///
/// Raw values correspond to numeric face value for pip cards (2-10).
/// Face cards and ace have special blackjack values accessed via computed properties.
public enum Rank: Int, CaseIterable, Sendable, Codable, Hashable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace

    /// The blackjack point value of this rank.
    /// Ace returns 1 (the "low" value); the caller is responsible for
    /// deciding whether to count it as 11 based on hand context.
    /// Face cards (J/Q/K) return 10. All others return their pip value.
    public var blackjackValue: Int {
        switch self {
        case .jack, .queen, .king: return 10
        case .ace: return 1
        default: return rawValue
        }
    }

    /// The Hi-Lo card counting system value for this rank.
    /// 2-6: +1 (low cards), 7-9: 0 (neutral), 10-A: -1 (high cards).
    public var hiLoValue: Int {
        switch self {
        case .two, .three, .four, .five, .six: return 1
        case .seven, .eight, .nine: return 0
        case .ten, .jack, .queen, .king, .ace: return -1
        }
    }

    /// Column index for strategy table lookup (dealer upcard).
    /// Maps 2 -> 0, 3 -> 1, ..., 10/J/Q/K -> 8, Ace -> 9.
    public var columnIndex: Int {
        blackjackValue == 1 ? 9 : blackjackValue - 2
    }
}

/// A single playing card with a rank and suit.
public struct Card: Sendable, Codable, Hashable {
    public let rank: Rank
    public let suit: Suit

    public init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }
}
