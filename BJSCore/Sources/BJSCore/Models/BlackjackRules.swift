/// A complete description of the blackjack rules in effect for a given game.
///
/// Covers all 11 rule variations specified in RULE-01:
/// deck count, dealer soft 17, blackjack payout, double after split,
/// resplit aces, hit split aces, max split hands, surrender rule,
/// double restriction, and peek rule.
///
/// Defaults represent a standard 6-deck S17 DAS game (most common US casino setup).
public struct BlackjackRules: Hashable, Sendable, Codable {

    /// Number of decks in the shoe.
    public enum DeckCount: Int, CaseIterable, Sendable, Codable, Hashable {
        case one = 1, two = 2, four = 4, six = 6, eight = 8
    }

    /// Whether the dealer stands or hits on soft 17.
    public enum DealerSoft17: String, CaseIterable, Sendable, Codable, Hashable {
        case stands  // S17
        case hits    // H17
    }

    /// Payout ratio for a player blackjack.
    public enum BlackjackPayout: String, CaseIterable, Sendable, Codable, Hashable {
        case threeToTwo   // 3:2
        case sixToFive    // 6:5
        case twoToOne     // 2:1
    }

    /// When the player may surrender.
    public enum SurrenderRule: String, CaseIterable, Sendable, Codable, Hashable {
        case none
        case late
        case early
    }

    /// Which initial two-card totals are eligible for doubling down.
    public enum DoubleRestriction: String, CaseIterable, Sendable, Codable, Hashable {
        case anyTwo
        case nineToEleven
        case tenToEleven
    }

    /// Whether the dealer peeks for blackjack (American) or not (European).
    public enum PeekRule: String, CaseIterable, Sendable, Codable, Hashable {
        case americanPeek
        case europeanNoPeek
    }

    public var deckCount: DeckCount = .six
    public var dealerSoft17: DealerSoft17 = .stands
    public var blackjackPayout: BlackjackPayout = .threeToTwo
    public var doubleAfterSplit: Bool = true
    public var resplitAces: Bool = false
    public var hitSplitAces: Bool = false
    public var maxSplitHands: Int = 4
    public var surrenderRule: SurrenderRule = .none
    public var doubleRestriction: DoubleRestriction = .anyTwo
    public var peekRule: PeekRule = .americanPeek

    public init() {}
}
