/// Basic strategy for one rule set.
///
/// Each cell is an ordered preference list; grading picks the first action that is legal
/// for the hand in play. Columns use `Rank.columnIndex` for the dealer upcard. Rows:
/// - `hardCells[total - 5]`: 17 rows (hard 5-21)
/// - `softCells[total - 13]`: 9 rows (soft 13-21)
/// - `pairCells[pairIndex]`: 10 rows (2,2 to 10,10, then A,A)
///
/// Every hard and soft list ends in `.hit` or `.stand`.
public struct StrategyTable: Sendable, Equatable {

    public let hardCells: [[[Action]]]
    public let softCells: [[[Action]]]
    public let pairCells: [[[Action]]]

    public init(hardCells: [[[Action]]], softCells: [[[Action]]], pairCells: [[[Action]]]) {
        self.hardCells = hardCells
        self.softCells = softCells
        self.pairCells = pairCells
    }

    /// The best action when every action is available (each cell's first preference).
    public var hardTotals: [[Action]] { hardCells.map { $0.map { $0[0] } } }
    public var softTotals: [[Action]] { softCells.map { $0.map { $0[0] } } }
    public var pairs: [[Action]] { pairCells.map { $0.map { $0[0] } } }

    /// The best of hit or stand: the play when double and surrender are not available.
    public var hardHitStand: [[Action]] { hardCells.map { $0.map(Self.hitOrStand) } }
    public var softHitStand: [[Action]] { softCells.map { $0.map(Self.hitOrStand) } }

    /// Returns the best action among `legal`.
    ///
    /// A two-card pair uses its pair row first. Otherwise, or when nothing in the pair row
    /// is legal (e.g. split at max hands), the hand's hard or soft row is used. Returns
    /// `.stand` if no preference is legal.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> Action {
        let col = dealerUpcard.columnIndex
        if hand.isPair, let action = pairCells[hand.pairIndex][col].first(where: legal.contains) {
            return action
        }
        let row = hand.isSoft ? softCells[hand.softIndex][col] : hardCells[hand.hardIndex][col]
        return row.first(where: legal.contains) ?? .stand
    }

    /// Returns the best action for a two-card hand with no prior split, allowing every
    /// action the rules permit.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, rules: BlackjackRules) -> Action {
        var legal: Set<Action> = [.hit, .stand]
        if hand.canDouble(rules: rules) { legal.insert(.double) }
        if hand.canSplit(rules: rules, currentSplitCount: 0) { legal.insert(.split) }
        if rules.surrenderRule != .none && hand.cards.count == 2 { legal.insert(.surrender) }
        return action(for: hand, dealerUpcard: dealerUpcard, legal: legal)
    }

    private static func hitOrStand(_ preferences: [Action]) -> Action {
        preferences.last { $0 == .hit || $0 == .stand } ?? .stand
    }
}
