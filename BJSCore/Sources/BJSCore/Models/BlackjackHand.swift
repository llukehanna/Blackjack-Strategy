/// A player's or dealer's blackjack hand.
///
/// Computes the best non-busting total (counting one ace as 11 when possible),
/// and provides rule-aware eligibility flags for player decisions.
public struct BlackjackHand: Sendable, Equatable {

    /// The cards currently in this hand.
    public private(set) var cards: [Card]

    /// Creates a hand with the given initial cards.
    public init(cards: [Card]) {
        self.cards = cards
    }

    // MARK: - Totals and flags

    /// The best (highest non-busting, or lowest if all bust) total for this hand.
    /// Counts all aces as 1, then adds 10 if any ace is present and it wouldn't bust.
    public var total: Int {
        var sum = cards.reduce(0) { $0 + $1.rank.blackjackValue }
        if cards.contains(where: { $0.rank == .ace }) && sum + 10 <= 21 {
            sum += 10
        }
        return sum
    }

    /// Whether this hand's total uses an ace counted as 11.
    public var isSoft: Bool {
        let baseSum = cards.reduce(0) { $0 + $1.rank.blackjackValue }
        return cards.contains(where: { $0.rank == .ace }) && baseSum + 10 <= 21
    }

    /// Whether this hand's total exceeds 21.
    public var isBust: Bool { total > 21 }

    /// Whether this is a two-card hand with both cards of the same rank.
    /// Note: same blackjack value (e.g., 10 and King) does NOT count as a pair.
    public var isPair: Bool {
        cards.count == 2 && cards[0].rank == cards[1].rank
    }

    /// Whether this is a natural blackjack (two-card 21).
    public var isBlackjack: Bool {
        cards.count == 2 && total == 21
    }

    // MARK: - Eligibility flags

    /// Whether the player can double down, given the current rules.
    /// Doubling is only allowed on the initial two cards, subject to total restrictions.
    public func canDouble(rules: BlackjackRules) -> Bool {
        guard cards.count == 2 else { return false }
        switch rules.doubleRestriction {
        case .anyTwo: return true
        case .nineToEleven: return (9...11).contains(total)
        case .tenToEleven: return (10...11).contains(total)
        }
    }

    /// Whether the player can split this hand, given the current rules and
    /// how many times the player has already split this round.
    public func canSplit(rules: BlackjackRules, currentSplitCount: Int) -> Bool {
        guard isPair else { return false }
        guard currentSplitCount < rules.maxSplitHands - 1 else { return false }
        // If already split and hand is aces, check resplitAces
        if currentSplitCount > 0 && cards[0].rank == .ace && !rules.resplitAces {
            return false
        }
        return true
    }

    /// Whether the player can surrender this hand, given the current rules.
    /// Surrender is only allowed on the initial two cards.
    public func canSurrender(rules: BlackjackRules) -> Bool {
        guard cards.count == 2 else { return false }
        return rules.surrenderRule != .none
    }

    // MARK: - Mutation

    /// Adds a card to this hand (hit, double, or deal).
    public mutating func addCard(_ card: Card) {
        cards.append(card)
    }

    // MARK: - Strategy table index helpers

    /// Index into the hard totals strategy table.
    /// Player total 5-21 maps to index 0-16.
    public var hardIndex: Int {
        max(0, min(16, total - 5))
    }

    /// Index into the soft totals strategy table.
    /// Soft 13-21 maps to index 0-8.
    public var softIndex: Int {
        max(0, min(8, total - 13))
    }

    /// Index into the pairs strategy table.
    /// Pair rank 2-Ace maps to index 0-9.
    public var pairIndex: Int {
        guard isPair else { return 0 }
        let rank = cards[0].rank
        return rank == .ace ? 9 : rank.blackjackValue - 2
    }
}
