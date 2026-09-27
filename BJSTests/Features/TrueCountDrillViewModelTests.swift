import Foundation
import Testing
import BJSCore
@testable import BJS

/// Hands out scripted questions in order, repeating the last.
@MainActor
final class ScriptedQuestions {
    var questions: [TrueCountQuestion]
    init(_ questions: [TrueCountQuestion]) { self.questions = questions }
    var maker: TrueCountDrillViewModel.QuestionMaker {
        { [self] _, _ in questions.count > 1 ? questions.removeFirst() : questions[0] }
    }
}

@MainActor
struct TrueCountDrillViewModelTests {

    func make(_ spy: SaveSpy = SaveSpy(), convention: TrueCountConvention = .exact,
              length: TrueCountLength = .questions(10), clock: TestClock = TestClock(),
              questions: [TrueCountQuestion] = [TrueCountQuestion(runningCount: 7, decksRemaining: 2)])
        -> TrueCountDrillViewModel {
        TrueCountDrillViewModel(setup: TrueCountSetup(length: length), rules: BlackjackRules(),
                                convention: convention, seed: 1, now: { clock.date },
                                makeQuestion: ScriptedQuestions(questions).maker,
                                persist: { try spy.persist($0) })
    }

    @Test("Starts on the first question; decks played is the shoe minus decks left")
    func starts() {
        let vm = make()
        #expect(vm.phase == .question)
        #expect(vm.questionNumber == 1)
        #expect(vm.question == TrueCountQuestion(runningCount: 7, decksRemaining: 2))
        #expect(vm.deckCount == 6)
        #expect(vm.decksPlayed == 4)
    }

    @Test("The .5 key is only offered under Exact", arguments: TrueCountConvention.allCases)
    func half(convention: TrueCountConvention) {
        #expect(make(convention: convention).allowsHalf == (convention == .exact))
    }

    @Test("Exact grades within 0.25; expected is the target; cards seen come from decks played")
    func exactGrading() {
        let clock = TestClock()
        let vm = make(clock: clock)
        clock.advance(2)
        vm.submit(3.5)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
        #expect(graded.kind == .trueCount)
        #expect(graded.expected == 3.5)
        #expect(graded.cardsSeen == 208)
        #expect(graded.responseMs == 2000)
        #expect(vm.question(for: graded) == TrueCountQuestion(runningCount: 7, decksRemaining: 2))
    }

    @Test("Floor grades the rounded-down value", arguments: [(3.0, true), (3.5, false), (4.0, false)])
    func floorGrading(answer: Double, correct: Bool) {
        let vm = make(convention: .floor)
        vm.submit(answer)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect == correct)
        #expect(graded.expected == 3)
    }

    @Test("NEXT asks a new question; the limit goes to the summary and saves once as countingTC")
    func limitSaves() throws {
        let spy = SaveSpy()
        let vm = make(spy, convention: .floor, length: .questions(2),
                      questions: [TrueCountQuestion(runningCount: 7, decksRemaining: 2),
                                  TrueCountQuestion(runningCount: -4, decksRemaining: 4)])
        vm.submit(3); vm.next()
        #expect(vm.phase == .question)
        #expect(vm.questionNumber == 2)
        #expect(vm.question == TrueCountQuestion(runningCount: -4, decksRemaining: 4))
        vm.submit(0); vm.next()
        #expect(vm.phase == .summary)
        let draft = try #require(spy.drafts.first)
        #expect(spy.drafts.count == 1)
        #expect(draft.module == .countingTC)
        #expect(draft.mode == "floor")
        #expect(draft.countChecks.map(\.isCorrect) == [true, false])
        #expect(draft.countChecks.map(\.expected) == [3, -1])
        vm.finish()
        #expect(spy.drafts.count == 1)
    }

    @Test("Endless keeps asking until finish()")
    func endless() {
        let vm = make(length: .endless)
        #expect(vm.questionLimit == nil)
        for _ in 0..<25 { vm.submit(3.5); vm.next() }
        #expect(vm.phase == .question)
        #expect(vm.questionNumber == 26)
        vm.finish()
        #expect(vm.phase == .summary)
    }

    @Test("Input outside its phase is ignored")
    func guards() {
        let vm = make()
        vm.next()
        #expect(vm.phase == .question)
        vm.submit(3.5)
        vm.submit(1)
        #expect(vm.checks.count == 1)
    }

    @Test("Resuming restarts the answer clock")
    func resume() {
        let clock = TestClock()
        let vm = make(clock: clock)
        clock.advance(30)
        vm.resumeAfterInterruption()
        clock.advance(1)
        vm.submit(3.5)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.responseMs == 1000)
    }

    @Test("Finishing with no checks doesn't save; a save failure still shows the summary")
    func saving() {
        let empty = SaveSpy()
        let vm = make(empty)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(empty.drafts.isEmpty)

        let failing = SaveSpy()
        failing.error = SaveFailure()
        let other = make(failing)
        other.submit(3.5)
        other.finish()
        #expect(other.phase == .summary)
        #expect(other.saveFailed)
    }

    @Test("Summary: score against the target and question rows")
    func summary() {
        let vm = make(length: .questions(2),
                      questions: [TrueCountQuestion(runningCount: 7, decksRemaining: 2),
                                  TrueCountQuestion(runningCount: 5, decksRemaining: 2.5)])
        vm.submit(3.5); vm.next()
        vm.submit(1); vm.next()
        let s = vm.summary
        #expect(s.title == "True count")
        #expect(s.rowsTitle == "Questions")
        #expect(s.secondsPerCard == nil)
        #expect(s.score.accuracy == 0.5)
        #expect(s.score.meanAbsoluteError == 0.5)
        #expect(s.rows.count == 2)
    }

    @Test("The default question maker uses the rules' deck count")
    func defaultMaker() {
        var rules = BlackjackRules()
        rules.deckCount = .one
        let vm = TrueCountDrillViewModel(setup: TrueCountSetup(), rules: rules, convention: .exact, seed: 3,
                                         persist: { _ in })
        #expect([0.25, 0.5, 0.75].contains(vm.question.decksRemaining))
    }
}
