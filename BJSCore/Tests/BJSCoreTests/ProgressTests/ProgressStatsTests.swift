import Foundation
import Testing
@testable import BJSCore

@Suite("ProgressStats")
struct ProgressStatsTests {

    let day: TimeInterval = 86_400
    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    func session(_ module: TrainingModule, day d: Int, decisions: Int = 0, correct: Int = 0,
                 checks: Int = 0, correctChecks: Int = 0) -> SessionSample {
        SessionSample(id: UUID(), module: module,
                      startedAt: Date(timeIntervalSince1970: Double(d) * day + 3_600),
                      decisionCount: decisions, correctDecisions: correct,
                      countChecks: checks, correctCountChecks: correctChecks)
    }

    @Test("Headline sums the chosen measure over chosen modules")
    func headline() {
        let sessions = [
            session(.strategy, day: 1, decisions: 50, correct: 45),
            session(.shoe, day: 2, decisions: 30, correct: 27, checks: 10, correctChecks: 8),
            session(.countingRC, day: 2, checks: 20, correctChecks: 15),
        ]
        let strategy = ProgressStats.headline(sessions: sessions, modules: [.strategy, .shoe],
                                              measure: .decisions, since: nil)
        #expect(strategy == Headline(attempts: 80, correct: 72))
        #expect(strategy.accuracy == 0.9)

        let counting = ProgressStats.headline(sessions: sessions, modules: [.countingRC, .countingTC, .shoe],
                                              measure: .countChecks, since: nil)
        #expect(counting == Headline(attempts: 30, correct: 23))

        let shoeCombined = ProgressStats.headline(sessions: sessions, modules: [.shoe],
                                                  measure: .combined, since: nil)
        #expect(shoeCombined == Headline(attempts: 40, correct: 35))
    }

    @Test("Headline respects the since date and has nil accuracy when empty")
    func headlineSince() {
        let sessions = [session(.strategy, day: 1, decisions: 10, correct: 5),
                        session(.strategy, day: 40, decisions: 10, correct: 10)]
        let recent = ProgressStats.headline(sessions: sessions, modules: [.strategy], measure: .decisions,
                                            since: Date(timeIntervalSince1970: 10 * day))
        #expect(recent.accuracy == 1.0)
        let none = ProgressStats.headline(sessions: [], modules: [.strategy], measure: .decisions, since: nil)
        #expect(none.accuracy == nil)
    }

    @Test("Daily trend groups by day, skips empty days, ascends")
    func trend() {
        let sessions = [
            session(.strategy, day: 3, decisions: 10, correct: 9),
            session(.strategy, day: 1, decisions: 10, correct: 5),
            session(.strategy, day: 1, decisions: 10, correct: 7),
            session(.countingRC, day: 2, checks: 5, correctChecks: 5),
        ]
        let points = ProgressStats.dailyTrend(sessions: sessions, modules: [.strategy], measure: .decisions,
                                              since: nil, calendar: utc)
        #expect(points.map(\.attempts) == [20, 10])
        #expect(points.map(\.accuracy) == [0.6, 0.9])
        #expect(points[0].day == Date(timeIntervalSince1970: 1 * day))
    }

    @Test("Heat map counts per cell and hides cells under 3 samples")
    func heatMap() {
        let cellA = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)
        let cellB = TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9)
        let t = Date(timeIntervalSince1970: 0)
        let samples = [
            DecisionSample(date: t, cell: cellA, isCorrect: false, responseMs: nil),
            DecisionSample(date: t, cell: cellA, isCorrect: true, responseMs: nil),
            DecisionSample(date: t, cell: cellA, isCorrect: false, responseMs: nil),
            DecisionSample(date: t, cell: cellA, isCorrect: true, responseMs: nil),
            DecisionSample(date: t, cell: cellB, isCorrect: false, responseMs: nil),
        ]
        let map = ProgressStats.heatMap(samples)
        #expect(map[cellA] == HeatCell(attempts: 4, errors: 2, errorRate: 0.5))
        #expect(map[cellB] == HeatCell(attempts: 1, errors: 1, errorRate: nil))
    }

    @Test("Current streak counts trailing correct decisions by date")
    func streak() {
        let cell = TrainingCell(handType: .hard, playerValue: 12, dealerUpcard: 4)
        func s(_ t: Double, _ ok: Bool) -> DecisionSample {
            DecisionSample(date: Date(timeIntervalSince1970: t), cell: cell, isCorrect: ok, responseMs: nil)
        }
        #expect(ProgressStats.currentStreak([s(3, true), s(1, true), s(2, false), s(4, true)]) == 2)
        #expect(ProgressStats.currentStreak([s(1, false)]) == 0)
        #expect(ProgressStats.currentStreak([]) == 0)
    }
}
