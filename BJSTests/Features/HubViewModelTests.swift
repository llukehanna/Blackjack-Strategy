import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct HubViewModelTests {

    let now = Date(timeIntervalSince1970: 100 * 86_400)
    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    func session(_ module: TrainingModule, daysAgo: Int, decisions: Int = 0, correct: Int = 0,
                 checks: Int = 0, correctChecks: Int = 0) -> SessionSample {
        SessionSample(id: UUID(), module: module, startedAt: now.addingTimeInterval(Double(-daysAgo) * 86_400),
                      decisionCount: decisions, correctDecisions: correct,
                      countChecks: checks, correctCountChecks: correctChecks)
    }

    func decision(_ correct: Bool, _ second: Double) -> DecisionSample {
        DecisionSample(date: Date(timeIntervalSince1970: second),
                       cell: TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10),
                       isCorrect: correct, responseMs: nil)
    }

    @Test("With no data every chip shows an em dash")
    func empty() {
        let model = HubViewModel()
        model.update(sessions: [], decisions: [], now: now, calendar: utc)
        #expect(model.strategyAccuracy == "—")
        #expect(model.countAccuracy == "—")
        #expect(model.streak == "—")
    }

    @Test("Strategy accuracy covers strategy and shoe sessions from the last 30 days")
    func strategyAccuracy() {
        let model = HubViewModel()
        model.update(sessions: [session(.strategy, daysAgo: 1, decisions: 40, correct: 36),
                                session(.shoe, daysAgo: 5, decisions: 10, correct: 9),
                                session(.strategy, daysAgo: 45, decisions: 100, correct: 0),
                                session(.countingRC, daysAgo: 1, checks: 5, correctChecks: 5)],
                     decisions: [], now: now, calendar: utc)
        #expect(model.strategyAccuracy == "90%")
    }

    @Test("Count accuracy covers RC, TC and shoe checks")
    func countAccuracy() {
        let model = HubViewModel()
        model.update(sessions: [session(.countingRC, daysAgo: 2, checks: 2, correctChecks: 1),
                                session(.countingTC, daysAgo: 3, checks: 1, correctChecks: 1),
                                session(.shoe, daysAgo: 4, checks: 1, correctChecks: 1)],
                     decisions: [], now: now, calendar: utc)
        #expect(model.countAccuracy == "75%")
    }

    @Test("Streak counts consecutive correct decisions from the newest")
    func streak() {
        let model = HubViewModel()
        model.update(sessions: [], decisions: [decision(true, 1), decision(false, 2),
                                               decision(true, 3), decision(true, 4)],
                     now: now, calendar: utc)
        #expect(model.streak == "2")
        model.update(sessions: [], decisions: [decision(false, 1)], now: now, calendar: utc)
        #expect(model.streak == "0")
    }

    @Test("Percent rounds to a whole number")
    func percent() {
        #expect(HubViewModel.percent(2.0 / 3.0) == "67%")
        #expect(HubViewModel.percent(1) == "100%")
        #expect(HubViewModel.percent(nil) == "—")
    }

    @Test("Module tiles: Strategy, Counting, Shoe Sim, Edge")
    func tiles() {
        #expect(HubModule.allCases.map { $0.title } == ["Strategy", "Counting", "Shoe Sim", "Edge"])
        #expect(HubModule.allCases.map { $0.step } == [3, 4, 7, 5])
    }
}
