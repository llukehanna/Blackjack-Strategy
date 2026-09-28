import Foundation

extension WhyContext {
    /// Rebuilds the context from a saved decision, for WHY from history (Step 6 spec §4).
    ///
    /// Legal actions aren't saved, so they're inferred: grading picks the first legal preference,
    /// so the chart's first preference for the cell was illegal exactly when it differs from the
    /// saved `correctAction`. One case can't be told apart: in an early-surrender
    /// composition-note cell (hard 14 vs a ten), a first-decision two-card hand and any other
    /// hard 14 save identical records. There the rebuild assumes the two-card hand
    /// (`compositionNote` true, no illegal lead). Ten-valued ranks rebuild as `.ten`.
    public init(cell: TrainingCell, userAction: Action?, correctAction: Action, rules: BlackjackRules,
                table: StrategyTable, id: UUID = UUID()) {
        let hand = Self.representativeHand(for: cell)
        let upcard = Self.rank(cell.dealerUpcard)
        // Split only for pair cells, so a hard 4 (2,2), hard 20 (10,10) or soft 12 (A,A) reads its
        // hard or soft row, as grading did once split wasn't legal.
        var legal: Set<Action> = [.hit, .stand, .double, .surrender]
        if cell.handType == .pair { legal.insert(.split) }
        let noteCell = table.compositionNoteApplies(to: hand, dealerUpcard: upcard)
        let first = table.preferences(for: hand, dealerUpcard: upcard, legal: legal).first
        let illegal = noteCell ? nil : first.flatMap { $0 == correctAction ? nil : $0 }
        self.init(id: id, handTotal: hand.total, handType: cell.handType,
                  pairRank: cell.handType == .pair ? hand.cards[0].rank : nil,
                  dealerUpCard: upcard, userAction: userAction, correctAction: correctAction,
                  rules: rules, preferredIllegal: illegal, surrenderContext: SurrenderContext(rules: rules),
                  compositionNote: noteCell)
    }

    /// A two-card hand in the cell's row: pairs as two of the rank, soft totals as A + x
    /// (A,A for soft 12), hard totals as 2 + x up to 11 and 10 + x from 12.
    static func representativeHand(for cell: TrainingCell) -> BlackjackHand {
        let v = cell.playerValue
        let ranks: [Rank]
        switch cell.handType {
        case .pair: ranks = [rank(v), rank(v)]
        case .soft: ranks = [.ace, v == 12 ? .ace : rank(v - 11)]
        case .hard: ranks = v <= 11 ? [.two, rank(v - 2)] : [.ten, rank(v - 10)]
        }
        return BlackjackHand(cards: ranks.enumerated().map { Card(rank: $1, suit: Suit.allCases[$0 % 4]) })
    }

    /// 2...10 by value; 11 is the ace.
    private static func rank(_ value: Int) -> Rank {
        value == 11 ? .ace : Rank(rawValue: value)!
    }
}
