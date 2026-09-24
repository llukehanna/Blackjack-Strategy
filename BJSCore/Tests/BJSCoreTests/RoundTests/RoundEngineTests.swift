import Testing
@testable import BJSCore

/// Builds a shoe that deals `ranks` in order (all spades; suits don't matter for play).
func stackedShoe(_ ranks: [Rank]) -> Shoe {
    Shoe(orderedCards: ranks.map { Card(rank: $0, suit: .spades) })
}

@Suite("RoundEngine — basics")
struct RoundEngineTests {

    // Deal order: P1, UP, P2, HOLE, then draws.

    @Test("Player blackjack pays according to payout rule",
          arguments: [(BlackjackRules.BlackjackPayout.threeToTwo, 1.5),
                      (.sixToFive, 1.2),
                      (.twoToOne, 2.0)])
    func playerBlackjack(payout: BlackjackRules.BlackjackPayout, expected: Double) throws {
        var rules = BlackjackRules()
        rules.blackjackPayout = payout
        var shoe = stackedShoe([.ace, .nine, .king, .seven])
        let round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .blackjack)
        #expect(round.totalNet == expected)
    }

    @Test("Both naturals push")
    func bothNaturals() throws {
        var shoe = stackedShoe([.ace, .ace, .king, .queen])
        let round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(round.hands[0].outcome == .push)
        #expect(round.totalNet == 0)
    }

    @Test("Dealer natural with American peek settles immediately as a loss")
    func dealerNaturalPeek() throws {
        var shoe = stackedShoe([.ten, .ace, .seven, .king])
        let round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .loss)
        #expect(round.totalNet == -1)
        #expect(round.legalActions.isEmpty)
    }

    @Test("ENHC: dealer natural found at the end takes doubled bet")
    func enhcTakesDouble() throws {
        var rules = BlackjackRules()
        rules.peekRule = .europeanNoPeek
        var shoe = stackedShoe([.five, .ace, .six, .king, .two])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.phase == .playerTurn)
        try round.apply(.double, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].isDoubled)
        #expect(round.hands[0].outcome == .loss)
        #expect(round.totalNet == -2)
    }

    @Test("ENHC + late surrender vs dealer natural still loses the full bet")
    func enhcLateSurrenderVsNatural() throws {
        var rules = BlackjackRules()
        rules.peekRule = .europeanNoPeek
        rules.surrenderRule = .late
        var shoe = stackedShoe([.ten, .ace, .six, .king])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.phase == .playerTurn)
        #expect(round.legalActions.contains(.surrender))
        try round.apply(.surrender, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .loss)
        #expect(round.totalNet == -1)
    }

    @Test("ENHC + early surrender vs dealer natural returns half")
    func enhcEarlySurrenderVsNatural() throws {
        var rules = BlackjackRules()
        rules.peekRule = .europeanNoPeek
        rules.surrenderRule = .early
        var shoe = stackedShoe([.ten, .ace, .six, .king])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.phase == .playerTurn)
        try round.apply(.surrender, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .surrendered)
        #expect(round.totalNet == -0.5)
    }

    @Test("ENHC: standing (not doubled) vs a dealer natural loses one unit")
    func enhcStandVsNatural() throws {
        var rules = BlackjackRules()
        rules.peekRule = .europeanNoPeek
        var shoe = stackedShoe([.ten, .ace, .six, .king])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.phase == .playerTurn)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .loss)
        #expect(round.totalNet == -1)
    }

    @Test("ENHC: busting vs a dealer natural still reports bust")
    func enhcBustVsNatural() throws {
        var rules = BlackjackRules()
        rules.peekRule = .europeanNoPeek
        var shoe = stackedShoe([.ten, .ace, .six, .king, .ten])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.phase == .playerTurn)
        try round.apply(.hit, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .bust)
        #expect(round.totalNet == -1)
    }

    @Test("American peek + early surrender: no dealer natural draws no dealer cards")
    func americanPeekEarlySurrenderNoNatural() throws {
        var rules = BlackjackRules()
        rules.surrenderRule = .early
        var shoe = stackedShoe([.ten, .ten, .six, .six])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.phase == .playerTurn)
        #expect(!round.dealer.isBlackjack)
        try round.apply(.surrender, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].outcome == .surrendered)
        #expect(round.totalNet == -0.5)
        #expect(round.dealer.cards.count == 2)
    }

    @Test("H17: dealer stands on a hard 17, no third card")
    func h17HardSeventeenStands() throws {
        var rules = BlackjackRules()
        rules.dealerSoft17 = .hits
        var shoe = stackedShoe([.ten, .ten, .eight, .seven])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.dealer.total == 17)
        #expect(round.dealer.cards.count == 2)
        #expect(round.hands[0].outcome == .win)
        #expect(round.totalNet == 1)
    }

    @Test("apply after settlement throws notPlayerTurn")
    func applyAfterSettledThrows() throws {
        var shoe = stackedShoe([.ace, .nine, .king, .seven])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(round.phase == .settled)
        var spareShoe = stackedShoe([.two])
        #expect(throws: RoundError.notPlayerTurn) {
            try round.apply(.stand, shoe: &spareShoe)
        }
    }

    @Test("Early surrender vs dealer natural returns half")
    func earlySurrenderVsNatural() throws {
        var rules = BlackjackRules()
        rules.surrenderRule = .early
        var shoe = stackedShoe([.ten, .ace, .six, .king])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.legalActions.contains(.surrender))
        try round.apply(.surrender, shoe: &shoe)
        #expect(round.hands[0].outcome == .surrendered)
        #expect(round.totalNet == -0.5)
    }

    @Test("Early surrender declined vs dealer natural loses one unit, no card drawn")
    func earlySurrenderDeclined() throws {
        var rules = BlackjackRules()
        rules.surrenderRule = .early
        var shoe = stackedShoe([.ten, .ace, .six, .king, .five])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.hit, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.totalNet == -1)
        #expect(round.drawnCards.count == 4)
    }

    @Test("Bust loses and dealer does not draw")
    func bustNoDealerDraw() throws {
        var shoe = stackedShoe([.ten, .six, .six, .ten, .king])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.hit, shoe: &shoe)
        #expect(round.hands[0].outcome == .bust)
        #expect(round.totalNet == -1)
        #expect(round.dealer.cards.count == 2)
    }

    @Test("S17: dealer stands on soft 17")
    func s17() throws {
        var shoe = stackedShoe([.ten, .ace, .eight, .six])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.dealer.total == 17)
        #expect(round.hands[0].outcome == .win)
        #expect(round.totalNet == 1)
    }

    @Test("H17: dealer hits soft 17")
    func h17() throws {
        var rules = BlackjackRules()
        rules.dealerSoft17 = .hits
        var shoe = stackedShoe([.ten, .ace, .eight, .six, .five, .nine])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.dealer.total == 21)
        #expect(round.hands[0].outcome == .loss)
    }

    @Test("Winning double pays two units")
    func doubleWin() throws {
        var shoe = stackedShoe([.six, .six, .five, .ten, .ten, .ten])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.double, shoe: &shoe)
        #expect(round.hands[0].isDoubled)
        #expect(round.hands[0].outcome == .win)
        #expect(round.totalNet == 2)
    }

    @Test("Late surrender returns half")
    func lateSurrender() throws {
        var rules = BlackjackRules()
        rules.surrenderRule = .late
        var shoe = stackedShoe([.ten, .ten, .six, .seven])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.surrender, shoe: &shoe)
        #expect(round.hands[0].outcome == .surrendered)
        #expect(round.totalNet == -0.5)
    }

    @Test("Legal actions for a fresh two-card hand")
    func legalActionsFresh() throws {
        var shoe = stackedShoe([.ten, .nine, .six, .eight, .two])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(round.legalActions == [.hit, .stand, .double])
        try round.apply(.hit, shoe: &shoe)
        #expect(round.legalActions == [.hit, .stand])
    }

    @Test("Double restriction 10-11 blocks doubling on 9")
    func doubleRestriction() throws {
        var rules = BlackjackRules()
        rules.doubleRestriction = .tenToEleven
        var shoe = stackedShoe([.five, .nine, .four, .eight])
        let round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(!round.legalActions.contains(.double))
    }

    @Test("Illegal action throws")
    func illegalThrows() throws {
        var shoe = stackedShoe([.ten, .nine, .six, .eight])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(throws: RoundError.illegalAction(.split)) {
            try round.apply(.split, shoe: &shoe)
        }
    }

    @Test("Hitting to 21 finishes the hand automatically")
    func autoFinishOn21() throws {
        var shoe = stackedShoe([.five, .nine, .six, .eight, .ten])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.hit, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].hand.total == 21)
        #expect(round.hands[0].outcome == .win)
    }

    @Test("drawnCards records every card taken from the shoe")
    func drawnCardsMatchesShoe() throws {
        var shoe = stackedShoe([.ten, .six, .two, .ten, .three, .five, .four])
        let before = shoe.dealtCount
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.hit, shoe: &shoe)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.drawnCards.count == shoe.dealtCount - before)
    }

    @Test("Short shoe throws shoeExhausted")
    func shortShoe() {
        var shoe = stackedShoe([.ten, .six])
        #expect(throws: RoundError.shoeExhausted) {
            _ = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        }
    }

    @Test("currentSpot mirrors the active hand and legal actions")
    func currentSpot() throws {
        var shoe = stackedShoe([.ten, .nine, .six, .eight])
        let round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        let spot = try #require(round.currentSpot)
        #expect(spot.hand.total == 16)
        #expect(spot.dealerUpcard == .nine)
        #expect(spot.legalActions == round.legalActions)
        let table = StrategyEngine().strategy(for: BlackjackRules())
        #expect(table.action(for: spot) == .hit)
    }
}
