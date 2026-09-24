import Foundation
import Testing
@testable import BJSCore

/// A decision spot with the given player ranks (all hearts) against `up`.
func makeSpot(_ ranks: [Rank], up: Rank, legal: Set<Action> = [.hit, .stand, .double, .split, .surrender]) -> DecisionSpot {
    DecisionSpot(hand: BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .hearts) }),
                 dealerUpcard: up, legalActions: legal)
}

/// A graded decision at a fixed date offset (seconds) from a reference date.
func makeDecision(_ sequence: Int, correct: Bool, responseMs: Int? = 1_000,
                  choice: DecisionChoice? = nil) -> GradedDecision {
    let spot = makeSpot([.ten, .six], up: .ten)
    let made = choice ?? .action(correct ? .hit : .stand)
    return GradedDecision(sequence: sequence, handNumber: sequence, spot: spot, choice: made,
                          correctAction: .hit, responseMs: responseMs,
                          decidedAt: Date(timeIntervalSinceReferenceDate: 800_000_000 + Double(sequence)))
}

@Suite("Strategy session config")
struct StrategySessionConfigTests {

    @Test("Modes: only Learn hints, only Speed is timed, only Weak spots uses weights")
    func modes() {
        #expect(StrategyMode.allCases == [.learn, .test, .speed, .weakSpots])
        #expect(StrategyMode.allCases.filter(\.showsHint) == [.learn])
        #expect(StrategyMode.allCases.filter(\.isTimed) == [.speed])
        #expect(StrategyMode.allCases.filter(\.usesWeakSpotWeights) == [.weakSpots])
    }

    @Test("Lengths are 25, 50, 100 hands or Endless")
    func lengths() {
        #expect(StrategySessionLength.allCases.map(\.handLimit) == [25, 50, 100, nil])
    }

    @Test("Defaults are Learn, 25 hands, all hands; the config round-trips through JSON")
    func configCoding() throws {
        #expect(StrategySessionConfig() == StrategySessionConfig(mode: .learn, length: .hands25, filter: .all))
        let config = StrategySessionConfig(mode: .weakSpots, length: .endless, filter: .pairs)
        let data = try JSONEncoder().encode(config)
        #expect(try JSONDecoder().decode(StrategySessionConfig.self, from: data) == config)
    }
}

@Suite("GradedDecision")
struct GradedDecisionTests {

    @Test("A decision is correct only when the chosen action is the correct one")
    func correctness() {
        #expect(makeDecision(1, correct: true).isCorrect)
        #expect(!makeDecision(1, correct: false).isCorrect)
        #expect(!makeDecision(1, correct: false, choice: .timeout).isCorrect)
    }

    @Test("Timeouts are stored as the string \"timeout\"; actions by raw value")
    func storage() {
        #expect(DecisionChoice.timeout.storageValue == "timeout")
        #expect(DecisionChoice.action(.surrender).storageValue == "surrender")
        #expect(DecisionChoice.timeout.action == nil)
        #expect(DecisionChoice.action(.hit).action == .hit)
    }

    @Test("The cell follows TrainingCell(spot:)")
    func cell() {
        #expect(makeDecision(1, correct: true).cell == TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10))
    }

    @Test("WhyContext for a splittable pair carries the pair rank")
    func whyPair() {
        let context = WhyContext(spot: makeSpot([.eight, .eight], up: .six), userAction: .hit,
                                 correctAction: .split, rules: BlackjackRules())
        #expect(context.handType == .pair)
        #expect(context.pairRank == .eight)
        #expect(context.handTotal == 16)
        #expect(context.dealerUpCard == .six)
        #expect(context.userAction == .hit)
        #expect(context.correctAction == .split)
    }

    @Test("A pair that can no longer split is explained by its total (A,A → soft 12)")
    func whyUnsplittablePair() {
        let context = WhyContext(spot: makeSpot([.ace, .ace], up: .six, legal: [.hit, .stand]),
                                 userAction: .stand, correctAction: .hit, rules: BlackjackRules())
        #expect(context.handType == .soft)
        #expect(context.handTotal == 12)
        #expect(context.pairRank == nil)
    }

    @Test("A timeout's WHY context uses the correct action as the user's action")
    func whyTimeout() {
        let decision = makeDecision(1, correct: false, choice: .timeout)
        let context = decision.whyContext(rules: BlackjackRules())
        #expect(context.userAction == .hit)
        #expect(context.correctAction == .hit)
        #expect(!WhyExplanation.explain(context).isEmpty)
    }
}

@Suite("StrategySessionSummary")
struct StrategySessionSummaryTests {

    @Test("No decisions: no accuracy, no mean time, zero streak")
    func empty() {
        let summary = StrategySessionSummary(decisions: [], handsPlayed: 0)
        #expect(summary.accuracy == nil)
        #expect(summary.meanResponseMs == nil)
        #expect(summary.bestStreak == 0)
        #expect(summary.mistakeCount == 0)
    }

    @Test("Accuracy, mistakes and hands played")
    func counts() {
        let decisions = [makeDecision(1, correct: true), makeDecision(2, correct: false),
                         makeDecision(3, correct: true), makeDecision(4, correct: true)]
        let summary = StrategySessionSummary(decisions: decisions, handsPlayed: 3)
        #expect(summary.decisionCount == 4)
        #expect(summary.correctDecisions == 3)
        #expect(summary.accuracy == 0.75)
        #expect(summary.mistakes.map(\.sequence) == [2])
        #expect(summary.handsPlayed == 3)
    }

    @Test("Best streak is the longest correct run in decision order, whatever the input order")
    func bestStreak() {
        let pattern = [true, true, false, true, true, true, false, true]
        let decisions = pattern.enumerated().map { makeDecision($0.offset + 1, correct: $0.element) }
        #expect(StrategySessionSummary(decisions: decisions.reversed(), handsPlayed: 8).bestStreak == 3)
        #expect(StrategySessionSummary.bestStreak(decisions) == 3)
        #expect(StrategySessionSummary.bestStreak([makeDecision(1, correct: false)]) == 0)
    }

    @Test("Mean reaction time skips decisions without one; timeouts count at the full countdown")
    func meanResponse() {
        let decisions = [makeDecision(1, correct: true, responseMs: 1_000),
                         makeDecision(2, correct: true, responseMs: nil),
                         makeDecision(3, correct: false, responseMs: 3_000, choice: .timeout)]
        let summary = StrategySessionSummary(decisions: decisions, handsPlayed: 3)
        #expect(summary.meanResponseMs == 2_000)
        #expect(summary.mistakes.map(\.choice) == [.timeout])
    }
}
