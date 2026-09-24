import Testing
@testable import BJSCore

@Suite("RoundEngine — properties")
struct RoundEnginePropertyTests {

    static let ruleSets: [BlackjackRules] = {
        var s17 = BlackjackRules()
        var h17ls = BlackjackRules(); h17ls.dealerSoft17 = .hits; h17ls.surrenderRule = .late
        var enhc = BlackjackRules(); enhc.peekRule = .europeanNoPeek; enhc.surrenderRule = .early
        var single = BlackjackRules(); single.deckCount = .one; single.blackjackPayout = .sixToFive
        single.doubleAfterSplit = false; single.maxSplitHands = 2
        var liberal = BlackjackRules(); liberal.resplitAces = true; liberal.hitSplitAces = true
        liberal.surrenderRule = .early; liberal.deckCount = .two
        return [s17, h17ls, enhc, single, liberal]
    }()

    static let allowedNets: Set<Double> = [-2, -1, -0.5, 0, 1, 1.2, 1.5, 2]

    @Test("20k random rounds per rule set keep every invariant",
          arguments: Array(RoundEnginePropertyTests.ruleSets.enumerated()))
    func randomRounds(pair: (offset: Int, element: BlackjackRules)) throws {
        let rules = pair.element
        var rng = SeededRandomNumberGenerator(seed: UInt64(1000 + pair.offset))
        let table = StrategyEngine().strategy(for: rules)
        var shoe = Shoe(deckCount: rules.deckCount.rawValue)
        shoe.shuffle(using: &rng)

        for roundNumber in 0..<20_000 {
            if shoe.cardsRemaining < 60 {
                shoe = Shoe(deckCount: max(rules.deckCount.rawValue, 2))
                shoe.shuffle(using: &rng)
            }
            let before = shoe.dealtCount
            var round = try RoundEngine(rules: rules, shoe: &shoe)
            var steps = 0
            while round.phase == .playerTurn {
                let spot = try #require(round.currentSpot)
                #expect(!spot.legalActions.isEmpty)
                let best = table.action(for: spot)
                #expect(spot.legalActions.contains(best))
                let action: Action = roundNumber % 3 == 0
                    ? best
                    : spot.legalActions.sorted { $0.rawValue < $1.rawValue }.randomElement(using: &rng)!
                try round.apply(action, shoe: &shoe)
                steps += 1
                #expect(steps < 200)
            }
            #expect(round.hands.count <= rules.maxSplitHands)
            #expect(round.drawnCards.count == shoe.dealtCount - before)
            for hand in round.hands {
                #expect(hand.outcome != nil)
                #expect(hand.isFinished)
                #expect(Self.allowedNets.contains(hand.net))
            }
        }
    }

    @Test("Hi-Lo running count over a fully played shoe returns to zero")
    func countBalancesOverShoe() throws {
        var rng = SeededRandomNumberGenerator(seed: 7)
        let rules = BlackjackRules()
        let table = StrategyEngine().strategy(for: rules)
        var shoe = Shoe(deckCount: 6)
        shoe.shuffle(using: &rng)
        var counter = HiLoCounter()

        while shoe.cardsRemaining >= 40 {
            var round = try RoundEngine(rules: rules, shoe: &shoe)
            while round.phase == .playerTurn {
                try round.apply(table.action(for: try #require(round.currentSpot)), shoe: &shoe)
            }
            counter.process(round.drawnCards)
        }
        while let card = shoe.deal() { counter.process(card) }
        #expect(counter.runningCount == 0)
    }
}
