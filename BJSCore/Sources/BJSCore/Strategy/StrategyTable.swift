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

    /// WoO's early-surrender composition note (1-2 decks, American peek): the two-card hard 14
    /// compositions, as sorted card values (e.g. [6, 8]), that surrender against a ten-value upcard.
    /// Other hard 14s follow the chart cell. nil when the note doesn't apply to the rules.
    public let hard14VsTenSurrenders: Set<[Int]>?

    init(hardCells: [[[Action]]], softCells: [[[Action]]], pairCells: [[[Action]]],
         hard14VsTenSurrenders: Set<[Int]>? = nil) {
        self.hardCells = hardCells
        self.softCells = softCells
        self.pairCells = pairCells
        self.hard14VsTenSurrenders = hard14VsTenSurrenders
    }

    /// The best action when every action is available (each cell's first preference).
    public var hardTotals: [[Action]] { hardCells.map { $0.map { $0[0] } } }
    public var softTotals: [[Action]] { softCells.map { $0.map { $0[0] } } }
    public var pairs: [[Action]] { pairCells.map { $0.map { $0[0] } } }

    /// The best of hit or stand: the play when double and surrender are not available.
    public var hardHitStand: [[Action]] { hardCells.map { $0.map(Self.hitOrStand) } }
    public var softHitStand: [[Action]] { softCells.map { $0.map(Self.hitOrStand) } }

    /// The preference list grading reads for this hand: the pair row while split is legal and
    /// the row has a legal action, `[hit, stand]` for an unsplittable soft 12, otherwise the
    /// hand's hard or soft row.
    public func preferences(for hand: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> [Action] {
        let col = dealerUpcard.columnIndex
        if hand.isPair, legal.contains(.split) {
            let row = pairCells[hand.pairIndex][col]
            if row.contains(where: legal.contains) { return row }
        }
        if hand.isSoft && hand.total == 12 { return [.hit, .stand] }
        return hand.isSoft ? softCells[hand.softIndex][col] : hardCells[hand.hardIndex][col]
    }

    /// Returns the best action among `legal`.
    ///
    /// A two-card pair uses its pair row first, but only while splitting is itself legal
    /// (e.g. not after a split without resplit aces); otherwise the pair row is skipped
    /// entirely, even if some other action in it is legal. Failing that, the hand's hard
    /// or soft row is used, with one exception: an unsplittable soft 12 (always A,A, once
    /// split is not legal) is graded `.hit` rather than the clamped soft-13 row, since hit
    /// beats double against every upcard once the pair can't be split. Before any of that,
    /// WoO's early-surrender composition note (`hard14VsTenSurrenders`) overrides the row for
    /// the listed two-card hard-14 compositions against a ten-value upcard. Returns `.stand`
    /// if no preference is legal.
    public func action(for hand: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> Action {
        if legal.contains(.surrender), let allowed = hard14VsTenSurrenders,
           compositionNoteApplies(to: hand, dealerUpcard: dealerUpcard),
           allowed.contains(hand.cards.map { $0.rank.blackjackValue }.sorted()) {
            return .surrender
        }
        return preferences(for: hand, dealerUpcard: dealerUpcard, legal: legal).first(where: legal.contains) ?? .stand
    }

    /// True for a two-card, non-pair hard 14 against a ten-value upcard when the rules carry
    /// WoO's early-surrender composition note.
    public func compositionNoteApplies(to hand: BlackjackHand, dealerUpcard: Rank) -> Bool {
        hard14VsTenSurrenders != nil && hand.cards.count == 2 && !hand.isPair && !hand.isSoft
            && hand.total == 14 && dealerUpcard.blackjackValue == 10
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
