import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
final class SaveSpy {
    var drafts: [SessionDraft] = []
    var error: Error?
    func persist(_ d: SessionDraft) throws {
        if let error { throw error }
        drafts.append(d)
    }
}

struct SaveFailure: Error {}

@MainActor
struct StrategySessionTests {

    func make(_ spy: SaveSpy, mode: StrategyMode = .test, length: StrategyLength = .hands(25),
              limit: Int? = nil, shoes: ScriptedShoes? = nil,
              now: @escaping () -> Date = { Date(timeIntervalSince1970: 1000) }) -> StrategyTrainerViewModel {
        let s = shoes ?? ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)])
        return StrategyTrainerViewModel(setup: StrategySetup(mode: mode, length: length), rules: BlackjackRules(),
                                        weights: nil, speedTimerSeconds: 3, handLimitOverride: limit, seed: 1,
                                        now: now, makeShoe: s.maker, persist: { try spy.persist($0) })
    }

    @Test("A Speed timeout records a wrong 'timeout', then NEXT abandons the hand")
    func timeout() {
        let spy = SaveSpy()
        let vm = make(spy, mode: .speed,
                      shoes: ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven),
                                            shoe(player: (.ten, .seven), up: .nine, hole: .eight)]))
        vm.timeoutElapsed(token: vm.decisionToken)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.chosen == .timeout)
        #expect(!graded.isCorrect)
        #expect(graded.abandonsHand)
        #expect(graded.responseMs == 3000)
        #expect(graded.why.userAction == nil)
        vm.next()
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.handNumber == 2)
        #expect(vm.handsCompleted == 1)
    }

    @Test("A stale timer token is ignored")
    func staleToken() {
        let vm = make(SaveSpy(), mode: .speed)
        let stale = vm.decisionToken - 1
        vm.timeoutElapsed(token: stale)
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.decisions.isEmpty)
    }

    @Test("A timeout is a no-op outside Speed mode: only Speed's mode is timed")
    func timeoutIgnoredOutsideSpeed() {
        let vm = make(SaveSpy(), mode: .test)
        vm.timeoutElapsed(token: vm.decisionToken)
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.decisions.isEmpty)
    }

    @Test("A timeout during feedback is ignored")
    func timeoutDuringFeedback() {
        let vm = make(SaveSpy(), mode: .speed)
        let token = vm.decisionToken
        vm.choose(.stand)
        vm.timeoutElapsed(token: token)
        #expect(vm.decisions.count == 1)
    }

    @Test("A timeout on the last hand goes to the summary")
    func timeoutLastHand() {
        let vm = make(SaveSpy(), mode: .speed, limit: 1)
        vm.timeoutElapsed(token: vm.decisionToken)
        vm.next()
        #expect(vm.phase == .summary)
    }

    @Test("Finishing a session saves it exactly once, with decisions in order")
    func saveOnce() throws {
        let spy = SaveSpy()
        let vm = make(spy, limit: 2)
        for _ in 0..<2 { vm.choose(.stand); vm.next(); vm.deal() }
        #expect(vm.phase == .summary)
        vm.finish()
        #expect(spy.drafts.count == 1)
        let draft = try #require(spy.drafts.first)
        #expect(draft.id == vm.sessionID)
        #expect(draft.module == .strategy)
        #expect(draft.mode == "test")
        #expect(draft.decisions.map { $0.handNumber } == [1, 2])
        #expect(draft.rules == BlackjackRules())
        #expect(vm.hasSaved)
    }

    @Test("Save partial mid-session saves what was graded and shows the summary")
    func savePartial() {
        let spy = SaveSpy()
        let vm = make(spy)
        #expect(!vm.canSavePartial)
        vm.choose(.stand)
        #expect(vm.canSavePartial)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(spy.drafts.count == 1)
        #expect(spy.drafts[0].decisions.count == 1)
        #expect(!vm.canSavePartial)
    }

    @Test("Finishing with no decisions shows the summary without saving")
    func finishEmpty() {
        let spy = SaveSpy()
        let vm = make(spy, length: .endless)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(spy.drafts.isEmpty)
    }

    @Test("A failed save flags the error and still shows the summary")
    func saveFailure() {
        let spy = SaveSpy()
        spy.error = SaveFailure()
        let vm = make(spy)
        vm.choose(.stand)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(vm.saveFailed)
        vm.finish()
        #expect(spy.drafts.isEmpty)
    }

    @Test("Summary numbers; average decision time only in Speed mode")
    func summary() {
        var clock = Date(timeIntervalSince1970: 1000)
        let shoes = ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight),   // stand correct
                                   shoe(player: (.ten, .six), up: .ten, hole: .seven),     // stand wrong
                                   shoe(player: (.ten, .seven), up: .ten, hole: .eight)])  // stand correct
        for mode in [StrategyMode.test, .speed] {
            let s = ScriptedShoes(shoes.shoes)
            let vm = make(SaveSpy(), mode: mode, limit: 3, shoes: s, now: { clock })
            for _ in 0..<3 {
                clock = clock.addingTimeInterval(2)
                vm.choose(.stand); vm.next(); vm.deal()
            }
            let sum = vm.summary
            #expect(sum.decisionCount == 3)
            #expect(sum.accuracy == 2.0 / 3.0)
            #expect(sum.mistakes.count == 1)
            #expect(sum.bestStreak == 1)
            #expect(sum.handsPlayed == 3)
            #expect(sum.averageDecisionMs == (mode == .speed ? 2000 : nil))
        }
    }

    @Test("Summary with no decisions has no accuracy")
    func emptySummary() {
        let vm = make(SaveSpy())
        #expect(vm.summary.accuracy == nil)
        #expect(vm.summary.handsPlayed == 0)
    }

    @Test("Restarting the decision clock bumps the token; a stale timeout after that is ignored")
    func restartDecisionClockBumpsToken() {
        let vm = make(SaveSpy(), mode: .speed)
        let originalToken = vm.decisionToken
        vm.restartDecisionClock()
        #expect(vm.decisionToken != originalToken)
        #expect(vm.phase == .awaitingDecision)
        // The dialog-era token is now stale: a timeout that fires for it must be ignored.
        vm.timeoutElapsed(token: originalToken)
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.decisions.isEmpty)
    }

    @Test("Restarting the decision clock measures the response time from the restart")
    func restartDecisionClockResetsStartTime() {
        // A timeout's responseMs is always the fixed timer duration, so exercise the reset via a
        // real choice instead, which measures elapsed time from `decisionStartedAt`.
        var clock = Date(timeIntervalSince1970: 1000)
        let vm = make(SaveSpy(), mode: .speed, now: { clock })
        clock = clock.addingTimeInterval(5) // time spent looking at the leave-session dialog
        vm.restartDecisionClock()
        clock = clock.addingTimeInterval(1.2)
        vm.choose(.stand)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.responseMs == 1200)
    }

    @Test("Restarting the decision clock outside awaitingDecision is a no-op")
    func restartDecisionClockNoOpOutsideAwaitingDecision() {
        let vm = make(SaveSpy(), mode: .speed)
        vm.choose(.stand)
        let phaseBefore = vm.phase
        let tokenBefore = vm.decisionToken
        #expect(phaseBefore != .awaitingDecision)
        vm.restartDecisionClock()
        #expect(vm.phase == phaseBefore)
        #expect(vm.decisionToken == tokenBefore)
    }
}
