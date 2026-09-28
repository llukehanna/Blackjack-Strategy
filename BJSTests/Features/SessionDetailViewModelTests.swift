import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct SessionDetailViewModelTests {

    let rules = BlackjackRules()
    let h16 = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)
    let h13 = TrainingCell(handType: .hard, playerValue: 13, dealerUpcard: 2)

    func detail(_ module: TrainingModule, mode: String?, decisions: [SessionDetail.Decision] = [],
                checks: [SessionDetail.Check] = [], bestStreak: Int = 0, meanMs: Double? = nil) -> SessionDetail {
        SessionDetail(sample: SessionSample(id: UUID(), module: module, startedAt: Date(timeIntervalSince1970: 0),
                                            decisionCount: decisions.count,
                                            correctDecisions: decisions.filter(\.isCorrect).count,
                                            countChecks: checks.count,
                                            correctCountChecks: checks.filter(\.sample.isCorrect).count),
                      mode: mode, rules: rules, bestStreak: bestStreak, meanResponseMs: meanMs,
                      decisions: decisions, checks: checks)
    }

    func decision(_ cell: TrainingCell, _ chosen: RecordedChoice, _ correct: Action) -> SessionDetail.Decision {
        SessionDetail.Decision(cell: cell, chosen: chosen, correctAction: correct,
                               isCorrect: chosen == .action(correct), responseMs: 1_000)
    }

    func check(_ kind: CountKind, _ expected: Double, _ answered: Double, _ correct: Bool, cards: Int) -> SessionDetail.Check {
        SessionDetail.Check(sample: CountSample(date: .distantPast, kind: kind, expected: expected, answered: answered,
                                                isCorrect: correct, responseMs: nil),
                            cardsSeen: cards)
    }

    @Test("Strategy: chips, mistakes with WHY, and timeouts")
    func strategy() throws {
        let model = SessionDetailViewModel(detail: detail(.strategy, mode: "test", decisions: [
            decision(h16, .action(.hit), .hit), decision(h16, .action(.stand), .hit), decision(h13, .timeout, .stand),
        ], bestStreak: 1))
        #expect(model.title == "Strategy · Test")
        #expect(model.captions == [RulesSummary.text(for: rules)])
        #expect(model.chips.map(\.label) == ["Accuracy", "Mistakes", "Best streak", "Decisions"])
        #expect(model.chips.map(\.value) == ["33%", "2", "1", "3"])
        #expect(model.mistakes.map(\.label) == ["Hard 16 vs 10", "Hard 13 vs 2"])
        #expect(model.mistakes.map(\.value) == ["Stand → Hit", "Time's up → Stand"])
        let first = try #require(model.mistakes.first)
        #expect(first.why.userAction == .stand)
        #expect(first.why.correctAction == .hit)
        #expect(model.mistakes[1].why.userAction == nil)
        #expect(model.checks.isEmpty)
        #expect(!model.showsTraceFootnote)
    }

    @Test("Speed mode adds the average decision time; Learn adds its caption")
    func speedAndLearn() {
        let speed = SessionDetailViewModel(detail: detail(.strategy, mode: "speed",
                                                          decisions: [decision(h16, .action(.hit), .hit)], meanMs: 1_450))
        #expect(speed.chips.last?.label == "Avg decision")
        #expect(speed.chips.last?.value == "1.4 s" || speed.chips.last?.value == "1.5 s")
        let learn = SessionDetailViewModel(detail: detail(.strategy, mode: "learn",
                                                          decisions: [decision(h16, .action(.hit), .hit)]))
        #expect(learn.title == "Strategy · Learn")
        #expect(learn.captions.last == SessionDetailViewModel.learnCaption)
        #expect(!learn.chips.contains { $0.label == "Avg decision" })
    }

    @Test("Running count: chips and check rows")
    func runningCount() {
        let model = SessionDetailViewModel(detail: detail(.countingRC, mode: nil, checks: [
            check(.runningCount, 4, 4, true, cards: 12), check(.runningCount, 4, 3, false, cards: 26),
        ]))
        #expect(model.title == "Running count")
        #expect(model.chips.map(\.label) == ["Accuracy", "Correct", "Mean error"])
        #expect(model.chips.map(\.value) == ["50%", "1 / 2", "0.5"])
        #expect(model.checks.map(\.label) == ["After card 12", "After card 26"])
        #expect(model.checks.map(\.value) == ["+4", "+4 · you said +3"])
        #expect(model.mistakes.isEmpty)
        #expect(model.showsTraceFootnote)
    }

    @Test("True count: convention caption, targets to one decimal")
    func trueCount() {
        let model = SessionDetailViewModel(detail: detail(.countingTC, mode: "exact", checks: [
            check(.trueCount, 2.8, 3, true, cards: 104), check(.trueCount, -1.5, -1, false, cards: 156),
            check(.trueCount, 2, 2, true, cards: 200),
        ]))
        #expect(model.title == "True count · Exact")
        #expect(model.captions.last == TrainingText.conventionRule(.exact))
        #expect(model.checks.map(\.label) == ["Check 1", "Check 2", "Check 3"])
        #expect(model.checks.map(\.value) == ["+2.8", "\u{2212}1.5 · you said \u{2212}1", "+2"])
        #expect(model.showsTraceFootnote)
    }
}
