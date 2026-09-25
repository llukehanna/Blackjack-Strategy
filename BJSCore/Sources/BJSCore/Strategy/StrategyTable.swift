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

    init(hardCells: [[[Action]]], softCells: [[[Action]]], pairCells: [[[Action]]]) {
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
    /// A two-card pair uses its pair row first, but only while splitting is itself legal
    /// (e.g. not after a split without resplit aces); otherwise the pair row is skipped
    /// entirely, even if some other action in it is legal. Failing that, the hand's hard
    /// or soft row is used, with one exception: an unsplittable soft 12 (always A,A, once
    /// split is not legal) is graded `.hit` rather than the clamped soft-13 row, since hit
    /// beats double against every upcard once the pair can't be split. Returns `.stand` if
    /// no preference is legal.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> Action {
        let col = dealerUpcard.columnIndex
        if hand.isPair, legal.contains(.split), let action = pairCells[hand.pairIndex][col].first(where: legal.contains) {
            return action
        }
        if hand.isSoft && hand.total == 12 {
            return legal.contains(.hit) ? .hit : .stand
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
