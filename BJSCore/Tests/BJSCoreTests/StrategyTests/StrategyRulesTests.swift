import Testing
@testable import BJSCore

@Suite("Strategy rule options and named cells")
struct StrategyRulesTests {

    private func hand(_ ranks: [Rank]) -> BlackjackHand {
        BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .clubs) })
    }

    private func rules(decks: BlackjackRules.DeckCount = .six, h17: Bool = false, das: Bool = true,
                       surrender: BlackjackRules.SurrenderRule = .none,
                       double: BlackjackRules.DoubleRestriction = .anyTwo,
                       peek: BlackjackRules.PeekRule = .americanPeek) -> BlackjackRules {
        var r = BlackjackRules()
        r.deckCount = decks
        r.dealerSoft17 = h17 ? .hits : .stands
        r.doubleAfterSplit = das
        r.surrenderRule = surrender
        r.doubleRestriction = double
        r.peekRule = peek
        return r
    }

    // MARK: Named spot checks (cells the old engine got wrong)

    @Test("6D S17: hard 16 vs 10 hits; soft 13 vs 5 and soft 15 vs 4 double")
    func sixDeckSpotChecks() {
        let table = StrategyEngine().strategy(for: rules())
        #expect(table.hardCells[16 - 5][Rank.ten.columnIndex] == [.hit])
        #expect(table.softCells[13 - 13][Rank.five.columnIndex] == [.double, .hit])
        #expect(table.softCells[15 - 13][Rank.four.columnIndex] == [.double, .hit])
    }

    @Test("European no hole card: 11 vs 10 and 11 vs A hit")
    func europeanElevenHits() {
        let table = StrategyEngine().strategy(for: RulePreset.europeanNoHoleCard.rules)
        #expect(table.hardCells[11 - 5][Rank.ten.columnIndex] == [.hit])
        #expect(table.hardCells[11 - 5][Rank.ace.columnIndex] == [.hit])
    }

    @Test("4 and 8 decks use the same chart as 6")
    func fourPlusDecksShareChart() {
        let engine = StrategyEngine()
        let six = engine.strategy(for: rules(decks: .six))
        #expect(engine.strategy(for: rules(decks: .four)) == six)
        #expect(engine.strategy(for: rules(decks: .eight)) == six)
    }

    // MARK: Pair rows

    @Test("1D S17 DAS: 7,7 vs 10 stands, although hard 14 vs 10 hits")
    func pairRowBeatsTotalRow() {
        let table = StrategyEngine().strategy(for: rules(decks: .one))
        let legal: Set<Action> = [.hit, .stand, .double, .split]
        #expect(table.action(for: hand([.seven, .seven]), dealerUpcard: .ten, legal: legal) == .stand)
        #expect(table.action(for: hand([.ten, .four]), dealerUpcard: .ten, legal: legal) == .hit)
    }

    // MARK: Rules-view lookup

    @Test("Two-card lookup offers surrender only when the rules allow it")
    func rulesViewLookup() {
        let none = rules()
        #expect(StrategyEngine().strategy(for: none)
            .action(for: hand([.ten, .six]), dealerUpcard: .ten, rules: none) == .hit)
        let late = rules(surrender: .late)
        #expect(StrategyEngine().strategy(for: late)
            .action(for: hand([.ten, .six]), dealerUpcard: .ten, rules: late) == .surrender)
    }
}
