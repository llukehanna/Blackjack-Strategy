import Foundation
import Testing
@testable import BJSCore

@Suite("StrategySession")
struct StrategySessionTests {

    private static let rules = BlackjackRules()
    private static let table = StrategyEngine().strategy(for: BlackjackRules())
    private static let date = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// Deal order: P1, UP, P2, HOLE, then draws.
    private static let hard16vs7 = stackedShoe([.ten, .seven, .six, .ten, .five, .nine, .nine])

    private func session(_ config: StrategySessionConfig = StrategySessionConfig(mode: .test),
                         shoes: [Shoe]? = nil, weights: [TrainingCell: Double]? = nil,
                         seed: UInt64 = 1) throws -> (StrategySession, SeededRandomNumberGenerator) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let source: StrategySession.HandSource = shoes.map { .scripted($0) } ?? .generated
        let session = try StrategySession(rules: Self.rules, config: config, table: Self.table,
                                          weights: weights, source: source, using: &rng)
        return (session, rng)
    }

    @Test("A new session deals hand 1 and waits for a decision")
    func starts() throws {
        let (session, _) = try session(shoes: [Self.hard16vs7])
        #expect(session.phase == .decision)
        #expect(session.handNumber == 1)
        #expect(session.handsCompleted == 0)
        #expect(session.currentSpot?.hand.total == 16)
        #expect(session.currentSpot?.dealerUpcard == .seven)
        #expect(session.correctAction == .hit)
    }

    @Test("STAND shows feedback before the outcome, and the next hand only comes after it")
    func standFeedbackBeforeOutcome() throws {
        var (session, rng) = try session(shoes: [Self.hard16vs7])
        let decision = try session.choose(.action(.stand), responseMs: 900, at: Self.date)
        #expect(session.phase == .feedback)
        #expect(session.lastDecision == decision)
        #expect(!decision.isCorrect)
        #expect(decision.correctAction == .hit)
        #expect(session.round.phase == .playerTurn)       // not applied yet: outcome still hidden
        #expect(session.handsCompleted == 0)
        #expect(session.currentSpot == nil)

        try session.continueAfterFeedback()
        #expect(session.phase == .outcome)
        #expect(session.round.phase == .settled)
        #expect(session.round.hands[0].outcome == .loss)  // 16 vs dealer 17 (7 + 10)
        #expect(session.handsCompleted == 1)
        #expect(session.handNumber == 1)

        try session.nextHand(using: &rng)
        #expect(session.phase == .decision)
        #expect(session.handNumber == 2)
    }

    @Test("Regression: every STAND on generated hands is followed by feedback, then the outcome, then the next hand",
          arguments: [1, 2, 3, 4, 5] as [UInt64])
    func standAlwaysGivesFeedback(seed: UInt64) throws {
        var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .hands50), seed: seed)
        for hand in 1...50 {
            #expect(session.phase == .decision)
            #expect(session.handNumber == hand)
            try session.choose(.action(.stand), responseMs: nil, at: Self.date)
            #expect(session.phase == .feedback)
            #expect(session.lastDecision?.handNumber == hand)
            #expect(session.round.phase == .playerTurn)
            try session.continueAfterFeedback()
            #expect(session.phase == .outcome)
            try session.nextHand(using: &rng)
        }
        #expect(session.phase == .finished)
        #expect(session.decisions.count == 50)
        #expect(session.handsCompleted == 50)
    }

    @Test("HIT that does not end the hand returns to a decision on the same hand")
    func hitContinues() throws {
        // 5,6 = 11 vs 10; the hit draws a 2 → hard 13.
        var (session, _) = try session(shoes: [stackedShoe([.five, .ten, .six, .seven, .two, .nine])])
        try session.choose(.action(.hit), responseMs: 500, at: Self.date)
        try session.continueAfterFeedback()
        #expect(session.phase == .decision)
        #expect(session.handNumber == 1)
        #expect(session.currentSpot?.hand.total == 13)
        #expect(session.currentSpot?.legalActions == [.hit, .stand])
    }

    @Test("Splits: each split hand's decisions are graded on the same hand number")
    func splitHands() throws {
        // 8,8 vs 6 | split draws 3 then 10 | double on 11 draws 9 | dealer 6+10 draws 10 (bust).
        var (session, _) = try session(shoes: [stackedShoe([.eight, .six, .eight, .ten, .three, .ten, .nine, .ten])])
        #expect(session.correctAction == .split)
        try session.choose(.action(.split), responseMs: 400, at: Self.date)
        try session.continueAfterFeedback()
        #expect(session.phase == .decision)
        #expect(session.round.hands.count == 2)
        #expect(session.currentSpot?.hand.total == 11)
        #expect(session.correctAction == .double)

        try session.choose(.action(.double), responseMs: 400, at: Self.date)
        try session.continueAfterFeedback()
        #expect(session.phase == .decision)
        #expect(session.currentSpot?.hand.total == 18)

        try session.choose(.action(.stand), responseMs: 400, at: Self.date)
        try session.continueAfterFeedback()
        #expect(session.phase == .outcome)
        #expect(session.decisions.map(\.handNumber) == [1, 1, 1])
        #expect(session.decisions.map(\.isCorrect) == [true, true, true])
        #expect(session.decisions.map(\.cell.handType) == [.pair, .hard, .hard])
        #expect(session.round.totalNet == 3)
    }

    @Test("A timeout is graded incorrect, then the correct action is played")
    func timeout() throws {
        var (session, _) = try session(StrategySessionConfig(mode: .speed), shoes: [Self.hard16vs7])
        let decision = try session.choose(.timeout, responseMs: 3_000, at: Self.date)
        #expect(!decision.isCorrect)
        #expect(decision.choice.storageValue == "timeout")
        #expect(decision.responseMs == 3_000)
        try session.continueAfterFeedback()
        // The hit (correct play) draws the 5: 21, which finishes the hand; dealer stands on 17.
        #expect(session.round.hands[0].hand.cards.count == 3)
        #expect(session.round.hands[0].hand.total == 21)
        #expect(session.phase == .outcome)
        #expect(session.round.hands[0].outcome == .win)
    }

    @Test("Illegal actions are rejected and nothing is graded")
    func illegal() throws {
        var (session, _) = try session(shoes: [Self.hard16vs7])     // no surrender in default rules
        #expect(throws: StrategySessionError.illegalAction(.surrender)) {
            try session.choose(.action(.surrender), responseMs: nil, at: Self.date)
        }
        #expect(session.phase == .decision)
        #expect(session.decisions.isEmpty)
    }

    @Test("Calls in the wrong phase throw and change nothing (e.g. a double tap)")
    func wrongPhase() throws {
        var (session, rng) = try session(shoes: [Self.hard16vs7])
        #expect(throws: StrategySessionError.wrongPhase) { try session.continueAfterFeedback() }
        #expect(throws: StrategySessionError.wrongPhase) { try session.nextHand(using: &rng) }
        try session.choose(.action(.stand), responseMs: nil, at: Self.date)
        #expect(throws: StrategySessionError.wrongPhase) {
            try session.choose(.action(.stand), responseMs: nil, at: Self.date)
        }
        #expect(session.decisions.count == 1)
        #expect(session.phase == .feedback)
    }

    @Test("Learn mode hints the correct action; the other modes never hint")
    func hints() throws {
        #expect(try session(StrategySessionConfig(mode: .learn), shoes: [Self.hard16vs7]).0.hint == .hit)
        for mode in [StrategyMode.test, .speed, .weakSpots] {
            #expect(try session(StrategySessionConfig(mode: mode), shoes: [Self.hard16vs7]).0.hint == nil)
        }
    }

    @Test("A 25-hand session finishes after the 25th outcome")
    func handLimit() throws {
        var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .hands25))
        while session.phase != .finished {
            switch session.phase {
            case .decision: try session.choose(.action(.stand), responseMs: nil, at: Self.date)
            case .feedback: try session.continueAfterFeedback()
            case .outcome: try session.nextHand(using: &rng)
            case .finished: break
            }
        }
        #expect(session.handNumber == 25)
        #expect(session.isLastHand)
        #expect(session.summary.handsPlayed == 25)
        #expect(session.summary.decisionCount == 25)
    }

    @Test("Endless never runs out of hands")
    func endless() throws {
        var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .endless))
        for _ in 1...120 {
            try session.choose(.action(.stand), responseMs: nil, at: Self.date)
            try session.continueAfterFeedback()
            try session.nextHand(using: &rng)
        }
        #expect(session.phase == .decision)
        #expect(session.handNumber == 121)
        #expect(!session.isLastHand)
    }

    @Test("finish() keeps graded decisions; the unfinished hand is not counted as played")
    func finishEarly() throws {
        var (session, _) = try session(shoes: [Self.hard16vs7])
        try session.choose(.action(.hit), responseMs: 700, at: Self.date)
        session.finish()
        #expect(session.phase == .finished)
        #expect(session.summary.decisionCount == 1)
        #expect(session.summary.handsPlayed == 0)
        #expect(throws: StrategySessionError.wrongPhase) { try session.continueAfterFeedback() }
    }

    @Test("The filter is respected", arguments: [HandFilter.hard, .soft, .pairs])
    func filter(_ filter: HandFilter) throws {
        var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .endless, filter: filter))
        for _ in 0..<40 {
            let spot = try #require(session.currentSpot)
            #expect(filter.includes(TrainingCell(spot: spot).handType))
            try session.choose(.action(.stand), responseMs: nil, at: Self.date)
            try session.continueAfterFeedback()
            try session.nextHand(using: &rng)
        }
    }

    @Test("Weights are used only in Weak-spots mode")
    func weakSpots() throws {
        let target = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 7)
        var weights: [TrainingCell: Double] = [:]
        for cell in TrainingCell.all { weights[cell] = 0.05 }
        weights[target] = 1_000

        #expect(try session(StrategySessionConfig(mode: .test), weights: weights).0.weights == nil)

        var hits = 0
        for seed in 1...20 as ClosedRange<UInt64> {
            let (session, _) = try session(StrategySessionConfig(mode: .weakSpots), weights: weights, seed: seed)
            #expect(session.weights != nil)
            if session.currentSpot.map(TrainingCell.init(spot:)) == target { hits += 1 }
        }
        #expect(hits >= 15)          // ≈ 98% of the weight sits on the target cell
    }

    @Test("The same seed deals the same hands")
    func deterministic() throws {
        func cells(seed: UInt64) throws -> [TrainingCell] {
            var (session, rng) = try session(StrategySessionConfig(mode: .test, length: .endless), seed: seed)
            var result: [TrainingCell] = []
            for _ in 0..<10 {
                result.append(TrainingCell(spot: try #require(session.currentSpot)))
                try session.choose(.action(.stand), responseMs: nil, at: Self.date)
                try session.continueAfterFeedback()
                try session.nextHand(using: &rng)
            }
            return result
        }
        #expect(try cells(seed: 42) == cells(seed: 42))
        #expect(try cells(seed: 42) != cells(seed: 43))
    }
}
