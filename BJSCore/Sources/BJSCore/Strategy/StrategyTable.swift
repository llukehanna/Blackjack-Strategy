/// A lookup table containing the optimal basic strategy action for every
/// player hand vs dealer upcard combination under a specific set of rules.
///
/// - `hardTotals[playerTotal - 5][dealerUpcard.columnIndex]` -- 17 rows x 10 columns
/// - `softTotals[playerTotal - 13][dealerUpcard.columnIndex]` -- 9 rows x 10 columns
/// - `pairs[pairRankIndex][dealerUpcard.columnIndex]` -- 10 rows x 10 columns
/// - `hardHitStand` / `softHitStand` -- same shapes as hard/soft, best of hit vs stand only.
///   Used when the preferred action is not legal (e.g. double on three cards).
public struct StrategyTable: Sendable, Equatable {

    public let hardTotals: [[Action]]
    public let softTotals: [[Action]]
    public let pairs: [[Action]]
    public let hardHitStand: [[Action]]
    public let softHitStand: [[Action]]

    /// Returns the optimal action assuming every action the table might pick is available
    /// (two-card hand, no prior split). Kept for the Wizard of Odds validation tests.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, rules: BlackjackRules) -> Action {
        if hand.isPair && hand.canSplit(rules: rules, currentSplitCount: 0) {
            let pairAction = pairs[hand.pairIndex][dealerUpcard.columnIndex]
            if pairAction == .split { return .split }
        }
        if hand.isSoft {
            return softTotals[hand.softIndex][dealerUpcard.columnIndex]
        }
        return hardTotals[hand.hardIndex][dealerUpcard.columnIndex]
    }

    /// Returns the best action among `legal`.
    ///
    /// Order: split (if legal and the pair table says split) → the hard/soft table's
    /// preferred action if legal → the hit/stand fallback → stand.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> Action {
        let col = dealerUpcard.columnIndex
        if hand.isPair && legal.contains(.split) && pairs[hand.pairIndex][col] == .split {
            return .split
        }
        let preferred = hand.isSoft ? softTotals[hand.softIndex][col] : hardTotals[hand.hardIndex][col]
        if legal.contains(preferred) { return preferred }
        let fallback = hand.isSoft ? softHitStand[hand.softIndex][col] : hardHitStand[hand.hardIndex][col]
        return legal.contains(fallback) ? fallback : .stand
    }
}
