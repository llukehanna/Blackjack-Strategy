import BJSCore
import Foundation
import Testing
@testable import BJS

@Suite("HubStats")
struct HubStatsTests {

    private static let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private static let calendar = Calendar(identifier: .gregorian)

    private func daysAgo(_ days: Int) -> Date {
        Self.calendar.date(byAdding: .day, value: -days, to: Self.now)!
    }

    private func session(_ module: TrainingModule, daysAgo days: Int, decisions: (Int, Int) = (0, 0),
                         checks: (Int, Int) = (0, 0)) -> SessionSample {
        SessionSample(id: UUID(), module: module, startedAt: daysAgo(days),
                      decisionCount: decisions.0, correctDecisions: decisions.1,
                      countChecks: checks.0, correctCountChecks: checks.1)
    }

    private func decision(secondsAgo: TimeInterval, correct: Bool) -> DecisionSample {
        DecisionSample(date: Self.now.addingTimeInterval(-secondsAgo),
                       cell: TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10),
                       isCorrect: correct, responseMs: nil)
    }

    @Test("No history: no accuracy, zero streak, dashes on screen")
    func empty() {
        let stats = HubStats.make(sessions: [], decisions: [], now: Self.now, calendar: Self.calendar)
        #expect(stats == HubStats(strategyAccuracy: nil, countAccuracy: nil, strategyStreak: 0))
        #expect(HubStats.percentText(stats.strategyAccuracy) == "—")
    }

    @Test("Last-30-day accuracy combines the right modules and drops older sessions")
    func accuracy() {
        let sessions = [
            session(.strategy, daysAgo: 2, decisions: (10, 8)),
            session(.shoe, daysAgo: 5, decisions: (2, 1), checks: (4, 3)),
            session(.strategy, daysAgo: 40, decisions: (10, 0)),      // outside the window
            session(.countingRC, daysAgo: 1, checks: (8, 5)),
        ]
        let stats = HubStats.make(sessions: sessions, decisions: [], now: Self.now, calendar: Self.calendar)
        #expect(stats.strategyAccuracy == 9.0 / 12.0)                  // (8 + 1) / (10 + 2)
        #expect(stats.countAccuracy == 8.0 / 12.0)                     // (3 + 5) / (4 + 8)
        #expect(HubStats.percentText(stats.strategyAccuracy) == "75%")
        #expect(HubStats.percentText(stats.countAccuracy) == "67%")
    }

    @Test("Streak counts consecutive correct decisions back from the newest")
    func streak() {
        let decisions = [
            decision(secondsAgo: 50, correct: true),
            decision(secondsAgo: 40, correct: false),
            decision(secondsAgo: 30, correct: true),
            decision(secondsAgo: 20, correct: true),
            decision(secondsAgo: 10, correct: true),
        ]
        let stats = HubStats.make(sessions: [], decisions: decisions.shuffled(), now: Self.now,
                                  calendar: Self.calendar)
        #expect(stats.strategyStreak == 3)
    }

    @Test("Percent text rounds to whole percent")
    func percent() {
        #expect(HubStats.percentText(1) == "100%")
        #expect(HubStats.percentText(0) == "0%")
        #expect(HubStats.percentText(0.875) == "88%")
    }
}
