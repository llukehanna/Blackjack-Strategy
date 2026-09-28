import Foundation
import Testing
@testable import BJSCore

struct WhyContextRebuildTests {

    static let ruleSets: [BlackjackRules] = {
        func rules(_ decks: BlackjackRules.DeckCount, _ soft17: BlackjackRules.DealerSoft17,
                   _ surrender: BlackjackRules.SurrenderRule, das: Bool = true,
                   double: BlackjackRules.DoubleRestriction = .anyTwo) -> BlackjackRules {
            var r = BlackjackRules()
            r.deckCount = decks
            r.dealerSoft17 = soft17
            r.surrenderRule = surrender
            r.doubleAfterSplit = das
            r.doubleRestriction = double
            return r
        }
        return RulePreset.allCases.map(\.rules) + [
            rules(.one, .stands, .early),
            rules(.two, .hits, .early),
            rules(.six, .stands, .early),
            rules(.one, .hits, .late, das: false, double: .tenToEleven),
            rules(.eight, .hits, .none, das: false, double: .nineToEleven),
        ]
    }()

    static let ranks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]

    func isNoteCell(_ cell: TrainingCell, _ table: StrategyTable) -> Bool {
        table.hard14VsTenSurrenders != nil && cell.handType == .hard && cell.playerValue == 14
            && cell.dealerUpcard == 10
    }

    @Test("Rebuilding from the saved cell matches the live context", arguments: ruleSets)
    func matchesLiveContext(rules: BlackjackRules) {
        let table = StrategyEngine().strategy(for: rules)
        var rng = SeededRandomNumberGenerator(seed: 6)
        var compared = 0
        for _ in 0..<5_000 {
            let count = [2, 2, 2, 3, 4].randomElement(using: &rng)!
            let hand = BlackjackHand(cards: (0..<count).map {
                Card(rank: Self.ranks.randomElement(using: &rng)!, suit: Suit.allCases[$0 % 4])
            })
            guard hand.total < 21 else { continue }
            let upcard = Self.ranks.randomElement(using: &rng)!
            var legal: Set<Action> = [.hit, .stand]
            if count == 2 && Bool.random(using: &rng) { legal.insert(.double) }
            if hand.isPair && Bool.random(using: &rng) { legal.insert(.split) }
            if count == 2 && rules.surrenderRule != .none && Bool.random(using: &rng) { legal.insert(.surrender) }
            let spot = DecisionSpot(hand: hand, dealerUpcard: upcard, legalActions: legal)
            let cell = TrainingCell(spot: spot)
            guard !isNoteCell(cell, table) else { continue }

            let id = UUID()
            let live = WhyContext(spot: spot, userAction: .hit, table: table, rules: rules, id: id)
            let rebuilt = WhyContext(cell: cell, userAction: .hit, correctAction: live.correctAction,
                                     rules: rules, table: table, id: id)
            #expect(rebuilt == live, "\(hand.cards.map(\.rank)) vs \(upcard), legal \(legal)")
            compared += 1
        }
        #expect(compared > 1_000)
    }

    @Test("Composition-note cells assume the first-decision two-card hand")
    func compositionNoteCell() throws {
        var rules = BlackjackRules()
        rules.deckCount = .one
        rules.surrenderRule = .early
        let table = StrategyEngine().strategy(for: rules)
        try #require(table.hard14VsTenSurrenders != nil)
        let cell = TrainingCell(handType: .hard, playerValue: 14, dealerUpcard: 10)

        // Two-card compositions, surrender legal: the rebuild matches the live context exactly.
        for ranks in [[Rank.ten, .four], [.eight, .six], [.nine, .five]] {
            let spot = DecisionSpot(hand: BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .spades) }),
                                    dealerUpcard: .ten, legalActions: [.hit, .stand, .double, .surrender])
            let id = UUID()
            let live = WhyContext(spot: spot, userAction: .stand, table: table, rules: rules, id: id)
            let rebuilt = WhyContext(cell: cell, userAction: .stand, correctAction: live.correctAction,
                                     rules: rules, table: table, id: id)
            #expect(rebuilt == live, "\(ranks)")
        }

        // Whatever was saved, a note cell carries the note and no illegal lead.
        for correct in [Action.hit, .surrender] {
            let rebuilt = WhyContext(cell: cell, userAction: .stand, correctAction: correct, rules: rules, table: table)
            #expect(rebuilt.compositionNote)
            #expect(rebuilt.preferredIllegal == nil)
        }
    }

    @Test("Ten-valued ranks rebuild as ten, ace upcard as ace, timeout as nil")
    func canonicalRanks() {
        let rules = BlackjackRules()
        let table = StrategyEngine().strategy(for: rules)
        let pair = WhyContext(cell: TrainingCell(handType: .pair, playerValue: 10, dealerUpcard: 11),
                              userAction: nil, correctAction: .stand, rules: rules, table: table)
        #expect(pair.pairRank == .ten)
        #expect(pair.handTotal == 20)
        #expect(pair.dealerUpCard == .ace)
        #expect(pair.userAction == nil)

        let aces = WhyContext(cell: TrainingCell(handType: .pair, playerValue: 11, dealerUpcard: 6),
                              userAction: .hit, correctAction: .split, rules: rules, table: table)
        #expect(aces.pairRank == .ace)
        #expect(aces.handTotal == 12)
    }

    @Test("A three-card soft 18 vs 6 saved as stand rebuilds with double as the illegal lead")
    func illegalDouble() {
        let rules = BlackjackRules()
        let table = StrategyEngine().strategy(for: rules)
        let c = WhyContext(cell: TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 6),
                           userAction: .hit, correctAction: .stand, rules: rules, table: table)
        #expect(c.preferredIllegal == .double)
        #expect(WhyExplanation.explain(c).hasPrefix("Doubling would be best"))
    }
}
