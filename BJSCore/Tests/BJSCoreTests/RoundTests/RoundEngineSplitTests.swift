import Testing
@testable import BJSCore

@Suite("RoundEngine — splits")
struct RoundEngineSplitTests {

    @Test("Split 8s vs 6, double first hand (DAS), dealer busts: +3")
    func splitEightsDoubleAfterSplit() throws {
        // P1 8, UP 6, P2 8, HOLE 10 | split draws 3 then 10 | double draws 9 | dealer draws 10
        var shoe = stackedShoe([.eight, .six, .eight, .ten, .three, .ten, .nine, .ten])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        #expect(round.legalActions.contains(.split))
        try round.apply(.split, shoe: &shoe)
        #expect(round.hands.count == 2)
        #expect(round.hands[0].hand.total == 11)
        #expect(round.hands[1].hand.total == 18)
        #expect(round.legalActions.contains(.double))
        #expect(!round.legalActions.contains(.surrender))
        try round.apply(.double, shoe: &shoe)
        #expect(round.activeHandIndex == 1)
        try round.apply(.stand, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.dealer.isBust)
        #expect(round.hands.map(\.net) == [2, 1])
        #expect(round.totalNet == 3)
    }

    @Test("No double after split when DAS is off")
    func noDAS() throws {
        var rules = BlackjackRules()
        rules.doubleAfterSplit = false
        var shoe = stackedShoe([.eight, .six, .eight, .ten, .three, .ten])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(!round.legalActions.contains(.double))
    }

    @Test("Split aces get one card each and 21 pays 1:1")
    func splitAcesOneCard() throws {
        var shoe = stackedShoe([.ace, .seven, .ace, .ten, .nine, .king])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands[0].hand.total == 20)
        #expect(round.hands[1].hand.total == 21)
        #expect(round.hands[1].outcome == .win)
        #expect(round.hands[1].net == 1)
        #expect(round.hands.allSatisfy { $0.isSplitAces })
    }

    @Test("Resplit aces allowed: A-A split hand may split again")
    func resplitAces() throws {
        var rules = BlackjackRules()
        rules.resplitAces = true
        // split -> A,A and A,5 ; resplit first -> A,6 and A,4
        var shoe = stackedShoe([.ace, .seven, .ace, .ten, .ace, .five, .six, .four])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.phase == .playerTurn)
        #expect(round.legalActions == [.stand, .split])
        try round.apply(.split, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands.map { $0.hand.total } == [17, 15, 16])
        #expect(round.hands.map(\.outcome) == [.push, .loss, .loss])
    }

    @Test("Resplit aces not allowed: A-A split hand is finished automatically")
    func noResplitAces() throws {
        var shoe = stackedShoe([.ace, .seven, .ace, .ten, .ace, .five])
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.phase == .settled)
        #expect(round.hands.count == 2)
    }

    @Test("Hit split aces allowed: split ace hand can hit")
    func hitSplitAces() throws {
        var rules = BlackjackRules()
        rules.hitSplitAces = true
        var shoe = stackedShoe([.ace, .seven, .ace, .ten, .two, .three, .four, .five])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.legalActions.contains(.hit))
    }

    @Test("maxSplitHands = 2 blocks a second split")
    func maxSplitHands() throws {
        var rules = BlackjackRules()
        rules.maxSplitHands = 2
        var shoe = stackedShoe([.eight, .six, .eight, .ten, .eight, .two])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.hands[0].hand.isPair)
        #expect(!round.legalActions.contains(.split))
    }

    @Test("maxSplitHands = 4 allows resplitting to four hands")
    func resplitToFour() throws {
        var shoe = stackedShoe([.eight, .six, .eight, .ten,
                                .eight, .two,   // split 1 -> [8,8] [8,2]
                                .eight, .three, // split 2 -> [8,8] [8,3] [8,2]
                                .ten, .nine])   // split 3 -> [8,10] [8,9] [8,3] [8,2]
        var round = try RoundEngine(rules: BlackjackRules(), shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.hands.count == 4)
        #expect(!round.legalActions.contains(.split))
    }

    @Test("Surrender is not legal after a split")
    func noSurrenderAfterSplit() throws {
        var rules = BlackjackRules()
        rules.surrenderRule = .late
        var shoe = stackedShoe([.eight, .ten, .eight, .seven, .eight, .two])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        #expect(round.legalActions.contains(.surrender))
        try round.apply(.split, shoe: &shoe)
        #expect(!round.legalActions.contains(.surrender))
    }

    @Test("A waiting split-ace hand is re-checked and auto-finished once a later split exhausts the resplit cap")
    func autoFinishRecheckAllSplitAceHands() throws {
        var rules = BlackjackRules()
        rules.resplitAces = true
        // split -> A,A / A,A | resplit hand 0 -> A,A / A,7 (A,A carried over still waiting)
        // | resplit hand 0 again -> A,5 / A,6, hitting maxSplitHands (4): the carried-over
        // A,A hand can no longer resplit and must be auto-finished too.
        var shoe = stackedShoe([.ace, .seven, .ace, .ten, .ace, .ace, .ace, .seven, .five, .six])
        var round = try RoundEngine(rules: rules, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        try round.apply(.split, shoe: &shoe)
        #expect(round.hands.count == 4)
        #expect(round.hands.allSatisfy { $0.isFinished })
        #expect(round.hands.map { $0.hand.total } == [16, 17, 18, 12])
        #expect(round.phase == .settled)
        #expect(round.hands.map(\.outcome) == [.loss, .push, .win, .loss])
        #expect(round.totalNet == -1)
    }
}
