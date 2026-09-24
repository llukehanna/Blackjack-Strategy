import BJSCore
import Foundation
@testable import BJS

/// Shared builders and fakes for the Strategy tests.
enum StrategyFixtures {
    static let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// A shoe dealing `ranks` in order (all spades). Deal order: P1, UP, P2, HOLE, then draws.
    static func shoe(_ ranks: [Rank]) -> Shoe {
        Shoe(orderedCards: ranks.map { Card(rank: $0, suit: .spades) })
    }

    /// Hard 16 (10, 6) vs 7, dealer 17 (7, 10); a hit draws a 5 (21). Basic strategy hits.
    static let hard16vs7: [Rank] = [.ten, .seven, .six, .ten, .five, .nine, .nine]
    /// 8, 8 vs 6 (hole 10); split draws 3 and 10; a double on 11 draws 9; the dealer draws 10 and busts.
    static let eightsVs6: [Rank] = [.eight, .six, .eight, .ten, .three, .ten, .nine, .ten]

    /// A graded hard-16-vs-7 decision (correct play: hit) made `sequence` seconds after `start`.
    static func decision(_ sequence: Int, choice: DecisionChoice, responseMs: Int? = 1_000) -> GradedDecision {
        let spot = DecisionSpot(hand: BlackjackHand(cards: [Card(rank: .ten, suit: .clubs), Card(rank: .six, suit: .hearts)]),
                                dealerUpcard: .seven, legalActions: [.hit, .stand, .double])
        return GradedDecision(sequence: sequence, handNumber: sequence, spot: spot, choice: choice,
                              correctAction: .hit, responseMs: responseMs,
                              decidedAt: start.addingTimeInterval(TimeInterval(sequence)))
    }

    static func snapshot(_ decisions: [GradedDecision], mode: StrategyMode = .test) -> StrategySessionSnapshot {
        StrategySessionSnapshot(id: UUID(), config: StrategySessionConfig(mode: mode, length: .hands25, filter: .all),
                                rules: BlackjackRules(), startedAt: start, endedAt: start.addingTimeInterval(600),
                                summary: StrategySessionSummary(decisions: decisions, handsPlayed: decisions.count),
                                decisions: decisions)
    }
}

/// A clock the tests move by hand.
@MainActor
final class FakeClock {
    var now = StrategyFixtures.start

    func advance(_ seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}

struct FakeSaveError: Error {}

/// Records saved snapshots, or throws when `fails` is set.
@MainActor
final class FakeStrategySaver: StrategySessionSaving {
    var saved: [StrategySessionSnapshot] = []
    var fails = false

    func save(_ snapshot: StrategySessionSnapshot) throws {
        if fails { throw FakeSaveError() }
        saved.append(snapshot)
    }
}
