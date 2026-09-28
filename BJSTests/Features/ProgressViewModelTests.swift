import Foundation
import SwiftData
import Testing
import BJSCore
@testable import BJS

@MainActor
struct ProgressViewModelTests {

    /// Day 100, noon UTC.
    let now = Date(timeIntervalSince1970: 100 * 86_400 + 12 * 3_600)
    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    func ago(_ days: Int) -> Date { now.addingTimeInterval(Double(-days) * 86_400) }
    func startOfDay(_ daysAgo: Int) -> Date { utc.startOfDay(for: ago(daysAgo)) }

    func session(_ module: TrainingModule, daysAgo: Int, decisions: Int = 0, correct: Int = 0,
                 checks: Int = 0, correctChecks: Int = 0) -> SessionSample {
        SessionSample(id: UUID(), module: module, startedAt: ago(daysAgo), decisionCount: decisions,
                      correctDecisions: correct, countChecks: checks, correctCountChecks: correctChecks)
    }

    func decision(_ cell: TrainingCell, _ correct: Bool, daysAgo: Int) -> DecisionSample {
        DecisionSample(date: ago(daysAgo), cell: cell, isCorrect: correct, responseMs: nil)
    }

    let h16 = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)

    @Test("Chips show per-module accuracy in the range; Shoe is combined")
    func chips() {
        let model = ProgressViewModel()
        let sessions = [session(.strategy, daysAgo: 0, decisions: 10, correct: 9),
                        session(.strategy, daysAgo: 8, decisions: 10, correct: 0),
                        session(.countingRC, daysAgo: 1, checks: 4, correctChecks: 3),
                        session(.countingTC, daysAgo: 2, checks: 2, correctChecks: 1),
                        session(.shoe, daysAgo: 3, decisions: 6, correct: 6, checks: 4, correctChecks: 2)]
        model.apply(entries: [], sessions: sessions, decisions: [], now: now, calendar: utc)
        #expect(model.chips.map(\.module) == [.strategy, .countingRC, .countingTC, .shoe])
        #expect(model.chips.map(\.value) == ["90%", "75%", "50%", "80%"])

        model.range = .allTime
        model.apply(entries: [], sessions: sessions, decisions: [], now: now, calendar: utc)
        #expect(model.chips.first?.value == "45%")
    }

    @Test("The trend has one point per day for the selected module, and a domain through today")
    func trend() {
        let model = ProgressViewModel()
        let sessions = [session(.strategy, daysAgo: 0, decisions: 10, correct: 9),
                        session(.strategy, daysAgo: 2, decisions: 4, correct: 2),
                        session(.countingRC, daysAgo: 1, checks: 2, correctChecks: 2)]
        model.apply(entries: [], sessions: sessions, decisions: [], now: now, calendar: utc)
        #expect(model.chartPoints.map(\.day) == [startOfDay(2), startOfDay(0)])
        #expect(model.chartPoints.map(\.accuracy) == [0.5, 0.9])
        #expect(model.chartSummary == "Strategy accuracy, 7 days: 2 days, latest 90%")
        #expect(model.chartDomain == startOfDay(6)...startOfDay(-1))

        model.trendModule = .countingRC
        #expect(model.chartPoints.map(\.accuracy) == [1])

        model.range = .allTime
        model.trendModule = .strategy
        model.apply(entries: [], sessions: sessions, decisions: [], now: now, calendar: utc)
        #expect(model.chartDomain == startOfDay(2)...startOfDay(-1))
    }

    @Test("No sessions at all is the empty state; sessions outside the range are not")
    func emptyStates() {
        let model = ProgressViewModel()
        model.apply(entries: [], sessions: [], decisions: [], now: now, calendar: utc)
        #expect(!model.hasAnySessions)

        let old = session(.strategy, daysAgo: 20, decisions: 5, correct: 5)
        model.apply(entries: [HistoryEntry(sample: old, mode: "test")], sessions: [old], decisions: [],
                    now: now, calendar: utc)
        #expect(model.hasAnySessions)
        #expect(model.chips.map(\.value) == ["—", "—", "—", "—"])
        #expect(model.chartPoints.isEmpty)
        #expect(!model.hasHeatData)
        #expect(model.history.count == 1)
    }

    @Test("Heat-map rows add hard 4 only when present; decisions outside the range are dropped")
    func heatRows() throws {
        let h4 = TrainingCell(handType: .hard, playerValue: 4, dealerUpcard: 5)
        let decisions = [decision(h16, false, daysAgo: 0), decision(h16, false, daysAgo: 1),
                         decision(h16, true, daysAgo: 2), decision(h4, true, daysAgo: 10)]
        let model = ProgressViewModel()
        model.apply(entries: [], sessions: [], decisions: decisions, now: now, calendar: utc)
        #expect(model.gridRows.map(\.id) == Array(5...20))
        let row16 = try #require(model.gridRows.first { $0.id == 16 })
        #expect(row16.label == "16")
        #expect(row16.cells.map(\.id) == Array(2...11))
        #expect(row16.cells.first { $0.id == 10 }?.bin == .severe)
        #expect(row16.cells.first { $0.id == 10 }?.accessibilityLabel == "Hard 16 vs 10")
        #expect(row16.cells.first { $0.id == 10 }?.accessibilityValue == "2 of 3 wrong (67%)")
        #expect(row16.cells.first { $0.id == 9 }?.bin == .insufficient)

        model.range = .allTime
        model.apply(entries: [], sessions: [], decisions: decisions, now: now, calendar: utc)
        #expect(model.gridRows.first?.id == 4)

        model.heatType = .pair
        #expect(model.gridRows.map(\.label).last == "A,A")
    }

    @Test("Selecting a cell shows its caption; selecting it again or changing hand type clears it")
    func selection() {
        let model = ProgressViewModel()
        model.apply(entries: [], sessions: [],
                    decisions: [decision(h16, false, daysAgo: 0), decision(h16, false, daysAgo: 0),
                                 decision(h16, true, daysAgo: 0)],
                    now: now, calendar: utc)
        #expect(model.caption == nil)
        model.select(row: 16, column: 10)
        #expect(model.caption == "Hard 16 vs 10 · 2 of 3 wrong (67%)")
        #expect(model.gridRows.first { $0.id == 16 }?.cells.first { $0.id == 10 }?.isSelected == true)
        model.select(row: 16, column: 10)
        #expect(model.caption == nil)
        model.select(row: 16, column: 10)
        model.heatType = .soft
        #expect(model.caption == nil)
    }

    @Test("History rows carry title, date and accuracy, in the order given")
    func historyRows() {
        let model = ProgressViewModel()
        let entries = [HistoryEntry(sample: session(.strategy, daysAgo: 0, decisions: 10, correct: 9), mode: "test"),
                       HistoryEntry(sample: session(.countingTC, daysAgo: 1, checks: 2, correctChecks: 1), mode: "exact"),
                       HistoryEntry(sample: session(.strategy, daysAgo: 2, decisions: 3, correct: 3), mode: "learn"),
                       HistoryEntry(sample: session(.countingRC, daysAgo: 3), mode: nil)]
        model.apply(entries: entries, sessions: [], decisions: [], now: now, calendar: utc)
        #expect(model.history.map(\.id) == entries.map(\.id))
        #expect(model.history.map(\.title) == ["Strategy · Test", "True count · Exact", "Strategy · Learn", "Running count"])
        #expect(model.history.map(\.accuracy) == ["90%", "50%", "100%", "—"])
        #expect(model.history.allSatisfy { !$0.dateText.isEmpty })
    }

    @Test("reload reads the store, excludes Learn from stats, and follows new saves")
    func reloadFromStore() throws {
        let container = try BJSModelContainer.make(inMemory: true)
        let store = SessionStore(context: container.mainContext)
        func draft(mode: String, correct: Bool) -> SessionDraft {
            SessionDraft(module: .strategy, mode: mode, startedAt: ago(0), endedAt: ago(0), rules: BlackjackRules(),
                         decisions: [DecisionDraft(handNumber: 1, cell: h16, chosen: .action(correct ? .hit : .stand),
                                                   correctAction: .hit, isCorrect: correct, responseMs: nil,
                                                   decidedAt: ago(0))])
        }
        try store.save(draft(mode: "learn", correct: false))
        let model = ProgressViewModel()
        model.reload(store: store, now: now, calendar: utc)
        #expect(model.hasAnySessions)
        #expect(model.history.count == 1)
        #expect(model.chips.first?.value == "—")
        #expect(!model.hasHeatData)

        try store.save(draft(mode: "test", correct: true))
        model.reload(store: store, now: now, calendar: utc)
        #expect(model.chips.first?.value == "100%")
        #expect(model.history.count == 2)
        #expect(!model.loadFailed)
    }
}
