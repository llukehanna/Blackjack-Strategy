/// A lookup table containing the optimal basic strategy action for every
/// player hand vs dealer upcard combination under a specific set of rules.
///
/// Structure per D-04:
/// - `hardTotals[playerTotal - 5][dealerUpcard.columnIndex]` -- 17 rows x 10 columns
/// - `softTotals[playerTotal - 13][dealerUpcard.columnIndex]` -- 9 rows x 10 columns
/// - `pairs[pairRankIndex][dealerUpcard.columnIndex]` -- 10 rows x 10 columns
public struct StrategyTable: Sendable, Equatable {

    /// Hard totals: player total 5-21 (17 rows) x dealer upcard 2-A (10 columns)
    public let hardTotals: [[Action]]

    /// Soft totals: player total soft 13-21 (9 rows) x dealer upcard 2-A (10 columns)
    public let softTotals: [[Action]]

    /// Pairs: pair of 2s through pair of As (10 rows) x dealer upcard 2-A (10 columns)
    public let pairs: [[Action]]

    /// Returns the optimal action for the given hand against the dealer upcard.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, rules: BlackjackRules) -> Action {
        if hand.isPair && hand.canSplit(rules: rules, currentSplitCount: 0) {
            let pairAction = pairs[hand.pairIndex][dealerUpcard.columnIndex]
            if pairAction == .split { return .split }
            // If pair table says don't split, fall through to hard/soft
        }
        if hand.isSoft {
            return softTotals[hand.softIndex][dealerUpcard.columnIndex]
        }
        return hardTotals[hand.hardIndex][dealerUpcard.columnIndex]
    }
}
