import Foundation
import Testing
import BJSCore
@testable import BJS

/// A clock the test moves by hand.
@MainActor
final class TestClock {
    var date = Date(timeIntervalSince1970: 1000)
    func advance(_ seconds: Double) { date = date.addingTimeInterval(seconds) }
}

func countCard(_ rank: Rank) -> Card { Card(rank: rank, suit: .clubs) }

@MainActor
struct RunningCountDrillViewModelTests {

    /// 2 → +1, K → 0 (checkpoint), 5 → +1, 6 → +2 (checkpoint, last).
    let drill = RunningCountDrill(groups: [[countCard(.two)], [countCard(.king)], [countCard(.five)], [countCard(.six)]],
                                  checkpoints: [1, 3])

    func make(_ spy: SaveSpy = SaveSpy(), clock: TestClock = TestClock(),
              setup: RunningCountSetup = RunningCountSetup()) -> RunningCountDrillViewModel {
        RunningCountDrillViewModel(setup: setup, rules: BlackjackRules(), drill: drill,
                                   now: { clock.date }, persist: { try spy.persist($0) })
    }

    /// Advances past every group up to and including `group`'s presentation.
    func advance(_ vm: RunningCountDrillViewModel, times: Int) {
        for _ in 0..<times { vm.advance(token: vm.presentationToken) }
    }

    @Test("Starts presenting the first group")
    func starts() {
        let vm = make()
        #expect(vm.phase == .presenting(group: 0))
        #expect(vm.visibleCards == [countCard(.two)])
        #expect(vm.cardsShown == 1)
        #expect(vm.totalCards == 4)
        #expect(!vm.canSavePartial)
    }

    @Test("advance moves to the next group; a stale token is ignored")
    func advanceAndStale() {
        let vm = make()
        let stale = vm.presentationToken
        vm.advance(token: stale)
        #expect(vm.phase == .presenting(group: 1))
        vm.advance(token: stale)
        #expect(vm.phase == .presenting(group: 1))
    }

    @Test("A checkpoint group is shown for its interval, then the keypad comes up")
    func checkpoint() {
        let vm = make()
        advance(vm, times: 2)
        #expect(vm.phase == .answering(group: 1))
        #expect(vm.visibleCards.isEmpty)
        #expect(vm.cardsShown == 2)
    }

    @Test("A correct answer grades against the running count and records response time")
    func correctAnswer() {
        let clock = TestClock()
        let vm = make(clock: clock)
        advance(vm, times: 2)
        clock.advance(1.5)
        vm.submit(0)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
        #expect(graded.kind == .runningCount)
        #expect(graded.expected == 0)
        #expect(graded.cardsSeen == 2)
        #expect(graded.responseMs == 1500)
        #expect(vm.canSavePartial)
        #expect(vm.trace(for: graded).map(\.runningCount) == [1, 0])
    }

    @Test("A wrong answer is recorded, and NEXT resumes from the correct count")
    func wrongThenResume() {
        let vm = make()
        advance(vm, times: 2)
        vm.submit(3)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(!graded.isCorrect)
        #expect(graded.answered == 3)
        vm.next()
        #expect(vm.phase == .presenting(group: 2))
        advance(vm, times: 2)
        vm.submit(2)
        guard case .feedback(let last) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(last.isCorrect)
        #expect(vm.trace(for: last).map(\.card) == [countCard(.five), countCard(.six)])
    }

    @Test("The last checkpoint's NEXT goes to the summary and saves once as countingRC")
    func finishSaves() throws {
        let spy = SaveSpy()
        let vm = make(spy)
        advance(vm, times: 2); vm.submit(0); vm.next()
        advance(vm, times: 2); vm.submit(1); vm.next()
        #expect(vm.phase == .summary)
        let draft = try #require(spy.drafts.first)
        #expect(spy.drafts.count == 1)
        #expect(draft.id == vm.sessionID)
        #expect(draft.module == .countingRC)
        #expect(draft.mode == nil)
        #expect(draft.countChecks.map(\.kind) == [.runningCount, .runningCount])
        #expect(draft.countChecks.map(\.isCorrect) == [true, false])
        #expect(draft.countChecks.map(\.cardsSeen) == [2, 4])
        vm.finish()
        #expect(spy.drafts.count == 1)
    }

    @Test("Input outside its phase is ignored")
    func guards() {
        let vm = make()
        vm.submit(0)
        vm.next()
        #expect(vm.phase == .presenting(group: 0))
        #expect(vm.checks.isEmpty)
    }

    @Test("Resuming re-arms the current group; while answering it restarts the answer clock")
    func resume() {
        let clock = TestClock()
        let vm = make(clock: clock)
        let before = vm.presentationToken
        vm.resumeAfterInterruption()
        #expect(vm.presentationToken == before + 1)
        #expect(vm.phase == .presenting(group: 0))
        advance(vm, times: 2)
        clock.advance(10)
        vm.resumeAfterInterruption()
        clock.advance(2)
        vm.submit(0)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.responseMs == 2000)
    }

    @Test("Save partial with no checks shows the summary without saving")
    func finishEmpty() {
        let spy = SaveSpy()
        let vm = make(spy)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(spy.drafts.isEmpty)
    }

    @Test("A save failure still shows the summary")
    func saveFailure() {
        let spy = SaveSpy()
        spy.error = SaveFailure()
        let vm = make(spy)
        advance(vm, times: 2); vm.submit(0)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(vm.saveFailed)
    }

    @Test("Summary: score, seconds per card and checkpoint rows")
    func summary() {
        var setup = RunningCountSetup()
        setup.groupSize = 2
        setup.pace = 1.0
        let vm = make(setup: setup)
        advance(vm, times: 2); vm.submit(0); vm.next()
        advance(vm, times: 2); vm.submit(1); vm.next()
        let s = vm.summary
        #expect(s.title == "Running count")
        #expect(s.rowsTitle == "Checkpoints")
        #expect(s.score.accuracy == 0.5)
        #expect(s.score.meanAbsoluteError == 0.5)
        #expect(s.secondsPerCard == 0.5)
        #expect(s.rows.map(\.label) == ["After card 2", "After card 4"])
    }

    @Test("The seeded initialiser builds the drill from the setup and honours a pace override")
    func seeded() {
        var setup = RunningCountSetup()
        setup.length = .cards(10)
        let vm = RunningCountDrillViewModel(setup: setup, rules: BlackjackRules(), paceOverride: 0.3, seed: 1,
                                            persist: { _ in })
        #expect(vm.totalCards == 10)
        #expect(vm.pace == 0.3)
        #expect(vm.drill.checkpoints == [9])
    }
}
