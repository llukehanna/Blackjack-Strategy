/// A lookup table containing the optimal basic strategy action for every
/// player hand vs dealer upcard combination under a specific set of rules.
///
/// - `hardTotals[playerTotal - 5][dealerUpcard.columnIndex]` -- 17 rows x 10 columns
/// - `softTotals[playerTotal - 13][dealerUpcard.columnIndex]` -- 9 rows x 10 columns
/// - `pairs[pairRankIndex][dealerUpcard.columnIndex]` -- 10 rows x 10 columns
/// - `hardHitStand` / `softHitStand` -- same shapes as hard/soft, best of hit vs stand only.
///   Used when the preferred action is not legal (e.g. double on three cards).
/// - `hardFour[dealerUpcard.columnIndex]` / `softTwelve[...]` -- the best non-split play for
///   2,2 (hard 4) and A,A (soft 12), used when splitting is not legal. These totals are
///   below the hard/soft tables' first rows. Their hit/stand fallback is always hit
///   (neither hand can bust by drawing).
public struct StrategyTable: Sendable, Equatable {

    public let hardTotals: [[Action]]
    public let softTotals: [[Action]]
    public let pairs: [[Action]]
    public let hardHitStand: [[Action]]
    public let softHitStand: [[Action]]
    public let hardFour: [Action]
    public let softTwelve: [Action]

    /// Returns the optimal action assuming every action the table might pick is available
    /// (two-card hand, no prior split). Kept for the Wizard of Odds validation tests.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, rules: BlackjackRules) -> Action {
        if hand.isPair && hand.canSplit(rules: rules, currentSplitCount: 0) {
            let pairAction = pairs[hand.pairIndex][dealerUpcard.columnIndex]
            if pairAction == .split { return .split }
        }
        return preferredAction(for: hand, column: dealerUpcard.columnIndex)
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
        let preferred = preferredAction(for: hand, column: col)
        if legal.contains(preferred) { return preferred }
        let fallback = hitStandAction(for: hand, column: col)
        return legal.contains(fallback) ? fallback : .stand
    }

    /// The hard/soft table's action, with hard 4 (2,2) and soft 12 (A,A) looked up in
    /// their own rows rather than clamped into hard 5 / soft 13.
    private func preferredAction(for hand: BlackjackHand, column col: Int) -> Action {
        if hand.isSoft {
            return hand.total == 12 ? softTwelve[col] : softTotals[hand.softIndex][col]
        }
        return hand.total == 4 ? hardFour[col] : hardTotals[hand.hardIndex][col]
    }

    private func hitStandAction(for hand: BlackjackHand, column col: Int) -> Action {
        if hand.isSoft {
            return hand.total == 12 ? .hit : softHitStand[hand.softIndex][col]
        }
        return hand.total == 4 ? .hit : hardHitStand[hand.hardIndex][col]
    }
}
