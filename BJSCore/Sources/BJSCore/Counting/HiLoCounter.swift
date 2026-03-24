/// A Hi-Lo card counting tracker that maintains a running count
/// and computes true count based on remaining decks.
///
/// Hi-Lo values: 2-6 = +1 (low cards), 7-9 = 0 (neutral), 10-A = -1 (high cards).
/// The Hi-Lo system is balanced: after dealing a complete shoe, the running count
/// returns to zero.
public struct HiLoCounter: Sendable {

    /// The current running count (sum of Hi-Lo values for all processed cards).
    public private(set) var runningCount: Int = 0

    public init() {}

    /// Process a single card, updating the running count.
    public mutating func process(_ card: Card) {
        runningCount += card.rank.hiLoValue
    }

    /// Process multiple cards at once, updating the running count.
    public mutating func process(_ cards: [Card]) {
        for card in cards {
            runningCount += card.rank.hiLoValue
        }
    }

    /// Compute the true count: running count divided by decks remaining.
    ///
    /// Returns 0 if decksRemaining is zero or negative (guard against division by zero).
    /// The caller typically passes `Shoe.decksRemaining` for this parameter.
    public func trueCount(decksRemaining: Double) -> Double {
        guard decksRemaining > 0 else { return 0 }
        return Double(runningCount) / decksRemaining
    }

    /// Reset the running count to zero (e.g., at the start of a new shoe).
    public mutating func reset() {
        runningCount = 0
    }
}
