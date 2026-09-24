import BJSCore
import Foundation
import Testing
@testable import BJS

@MainActor
@Suite("StrategyTrainerViewModel")
struct StrategyTrainerViewModelTests {

    private let clock = FakeClock()
    private let saver = FakeStrategySaver()

    private func makeViewModel(_ config: StrategySessionConfig = StrategySessionConfig(mode: .test),
                               shoes: [[Rank]]? = nil, history: [DecisionSample] = [],
                               seed: UInt64 = 7, timer: Double = 3.0) -> StrategyTrainerViewModel {
        let clock = self.clock
        let source: StrategySession.HandSource = shoes.map { .scripted($0.map(StrategyFixtures.shoe)) } ?? .generated
        return StrategyTrainerViewModel(config: config, rules: BlackjackRules(), speedTimerSeconds: timer,
                                        history: history, seed: seed, source: source, saver: saver,
                                        now: { clock.now })
    }

    private func history(_ count: Int) -> [DecisionSample] {
        (0..<count).map { index in
            DecisionSample(date: StrategyFixtures.start.addingTimeInterval(TimeInterval(-index)),
                           cell: TrainingCell(handType: .hard, playerValue: 12, dealerUpcard: 2),
                           isCorrect: index % 2 == 0, responseMs: nil)
        }
    }

    // MARK: - Spec §7 required regression (the Phase 7 bug)

    @Test("STAND always produces feedback before the next hand",
          arguments: StrategyMode.allCases)
    func standAlwaysProducesFeedbackBeforeTheNextHand(mode: StrategyMode) {
        let vm = makeViewModel(StrategySessionConfig(mode: mode, length: .hands50), history: history(60))
        for hand in 1...50 {
            #expect(vm.phase == .decision)
            #expect(vm.handNumber == hand)
            #expect(vm.allowedActions.contains(.stand))

            vm.choose(.stand)
            // Feedback first: same hand, outcome still hidden, dock disabled.
            #expect(vm.phase == .feedback)
            #expect(vm.feedback?.choice == .action(.stand))
            #expect(vm.feedback?.handNumber == hand)
            #expect(vm.handNumber == hand)
            #expect(!vm.isDealerRevealed)
            #expect(vm.allowedActions.isEmpty)

            // Only NEXT reveals the outcome...
            vm.next()
            #expect(vm.phase == .outcome)
            #expect(vm.isDealerRevealed)
            #expect(vm.feedback == nil)

            // ...and only "Next hand" deals the next one.
            vm.nextHand()
        }
        #expect(vm.isFinished)
        #expect(vm.summary.decisionCount == 50)
        #expect(saver.saved.count == 1)
    }

    @Test("STAND on a scripted hard 16 vs 7: feedback, then the loss, then hand 2")
    func standScripted() {
        let vm = makeViewModel(shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.stand)
        #expect(vm.feedback.map(DecisionFeedback.headline) == "The play is Hit")
        #expect(vm.playerHands[0].outcome == nil)
        vm.next()
        #expect(vm.phase == .outcome)
        #expect(StrategyText.outcome(vm.playerHands[0]) == "Loss \u{2212}1")
        vm.nextHand()
        #expect(vm.phase == .decision)
        #expect(vm.handNumber == 2)
    }

    @Test("Splitting eights vs 6: STAND on hand 1 gives feedback with the hole card still down, then hand 2")
    func splitStandHand1ThenHand2() {
        let vm = makeViewModel(shoes: [StrategyFixtures.eightsVs6])
        vm.choose(.split)
        vm.next()                              // past the split's own feedback: hand 1's decision
        #expect(vm.phase == .decision)
        #expect(vm.activeHandIndex == 0)

        vm.choose(.stand)
        #expect(vm.phase == .feedback)
        #expect(!vm.isDealerRevealed)           // the round has not been applied yet
        #expect(vm.playerHands[0].outcome == nil)

        vm.next()
        #expect(vm.phase == .decision)
        #expect(vm.activeHandIndex == 1)        // hand 2, still the same dealt hand
        #expect(vm.handNumber == 1)
        #expect(!vm.isDealerRevealed)
    }

    @Test("A double tap grades only one decision")
    func doubleTap() {
        let vm = makeViewModel(shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.stand)
        vm.choose(.stand)
        vm.choose(.hit)
        #expect(vm.summary.decisionCount == 1)
    }

    @Test("Learn mode rings the correct action; Test mode shows no hint")
    func hints() {
        #expect(makeViewModel(StrategySessionConfig(mode: .learn), shoes: [StrategyFixtures.hard16vs7]).hint == .hit)
        #expect(makeViewModel(StrategySessionConfig(mode: .test), shoes: [StrategyFixtures.hard16vs7]).hint == nil)
    }

    @Test("Reaction time and decidedAt come from the clock, per decision")
    func reactionTime() {
        let vm = makeViewModel(shoes: [StrategyFixtures.eightsVs6])
        clock.advance(1.25)
        vm.choose(.split)
        #expect(vm.feedback?.responseMs == 1_250)
        #expect(vm.feedback?.decidedAt == StrategyFixtures.start.addingTimeInterval(1.25))

        clock.advance(4)                     // reading the feedback does not count
        vm.next()
        clock.advance(0.5)
        vm.choose(.double)
        #expect(vm.feedback?.responseMs == 500)
        #expect(vm.feedback?.decidedAt == StrategyFixtures.start.addingTimeInterval(5.75))
    }

    @Test("Each new decision gets a new countdown token (splits included)")
    func tokens() {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.eightsVs6])
        let first = vm.decisionToken
        #expect(vm.countdownToken == first)
        vm.choose(.split)
        #expect(vm.countdownToken == nil)    // no countdown while feedback shows
        vm.next()
        #expect(vm.countdownToken == first + 1)
    }

    @Test("Speed: a timeout records an incorrect 'timeout' at the full countdown; stale timers are ignored")
    func timeout() {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.hard16vs7], timer: 2.5)
        vm.timeExpired(token: vm.decisionToken - 1)
        #expect(vm.phase == .decision)

        vm.timeExpired(token: vm.decisionToken)
        let decision = vm.feedback
        #expect(decision?.choice == .timeout)
        #expect(decision?.isCorrect == false)
        #expect(decision?.responseMs == 2_500)
        #expect(decision.map(DecisionFeedback.headline) == "Time's up: Hit")

        vm.timeExpired(token: vm.decisionToken)
        #expect(vm.summary.decisionCount == 1)
    }

    @Test("Outside Speed mode there is no countdown and timeouts do nothing")
    func noTimeoutInTest() {
        let vm = makeViewModel(StrategySessionConfig(mode: .test), shoes: [StrategyFixtures.hard16vs7])
        #expect(vm.countdownToken == nil)
        vm.timeExpired(token: vm.decisionToken)
        #expect(vm.phase == .decision)
    }

    @Test("Reaching the hand limit shows the summary and saves once, with every decision")
    func completes() throws {
        let vm = makeViewModel(StrategySessionConfig(mode: .learn, length: .hands25))
        while !vm.isFinished {
            clock.advance(1)
            switch vm.phase {
            case .decision: vm.choose(vm.hint ?? .stand)
            case .feedback: vm.next()
            case .outcome: vm.nextHand()
            case .finished: break
            }
        }
        #expect(vm.isSaved)
        #expect(!vm.isShowingSaveError)
        let snapshot = try #require(saver.saved.first)
        #expect(saver.saved.count == 1)
        #expect(snapshot.config.mode == .learn)
        #expect(snapshot.summary.handsPlayed == 25)
        #expect(snapshot.summary.accuracy == 1)
        #expect(snapshot.decisions.count == snapshot.summary.decisionCount)
        let dates = snapshot.decisions.map(\.decidedAt)
        #expect(dates == dates.sorted() && Set(dates).count == dates.count)
        #expect(snapshot.startedAt == StrategyFixtures.start)
        #expect(snapshot.endedAt == clock.now)
    }

    @Test("A save failure shows a non-blocking alert and still shows the summary")
    func saveFailure() {
        saver.fails = true
        let vm = makeViewModel(StrategySessionConfig(mode: .test, length: .endless), shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.hit)
        vm.next()
        vm.endSession()
        #expect(vm.isFinished)
        #expect(vm.isShowingSaveError)
        #expect(!vm.isSaved)
        #expect(vm.summary.decisionCount == 1)
    }

    @Test("Ending a session with no graded decisions still finishes, but saves nothing")
    func endEmptySession() {
        let vm = makeViewModel(StrategySessionConfig(mode: .test, length: .endless), shoes: [StrategyFixtures.hard16vs7])
        vm.endSession()
        #expect(vm.isFinished)
        #expect(vm.summary.decisionCount == 0)
        #expect(saver.saved.isEmpty)
        #expect(!vm.isSaved)
        #expect(!vm.isShowingSaveError)
    }

    @Test("Leaving before any graded decision closes at once and saves nothing")
    func leaveEmpty() {
        let vm = makeViewModel(shoes: [StrategyFixtures.hard16vs7])
        #expect(vm.requestLeave())
        #expect(!vm.isConfirmingLeave)
        #expect(saver.saved.isEmpty)
    }

    @Test("Leaving mid-session asks; Save partial saves and shows the summary")
    func leaveSavePartial() throws {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.stand)
        #expect(!vm.requestLeave())
        #expect(vm.isConfirmingLeave)
        vm.savePartial()
        #expect(vm.isFinished)
        #expect(try #require(saver.saved.first).decisions.count == 1)
        #expect(vm.requestLeave())            // on the summary, close closes
    }

    @Test("Discard saves nothing; Keep playing restarts the Speed countdown")
    func leaveDiscardOrKeep() {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.hit)
        vm.next()                             // 16 + 5 = 21 → outcome
        vm.nextHand()                         // hand 2 (the script repeats)
        let token = vm.decisionToken
        #expect(!vm.requestLeave())
        #expect(vm.countdownToken == nil)     // paused while the prompt shows
        vm.keepPlaying()
        #expect(vm.countdownToken == token + 1)

        #expect(!vm.requestLeave())
        vm.discard()
        #expect(saver.saved.isEmpty)
    }

    @Test("Returning to the foreground mid-decision restarts the Speed countdown; a no-op elsewhere")
    func resumeCountdown() {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.hard16vs7])
        let token = vm.decisionToken
        let startedAt = vm.decisionStartedAt

        clock.advance(1.5)
        vm.resumeCountdown()
        #expect(vm.decisionStartedAt == startedAt.addingTimeInterval(1.5))
        #expect(vm.decisionToken == token + 1)

        // Outside `.decision` (feedback showing) resumeCountdown does nothing.
        vm.choose(.hit)                        // 16 + 5 = 21 → feedback
        #expect(vm.phase == .feedback)
        let feedbackToken = vm.decisionToken
        let feedbackStartedAt = vm.decisionStartedAt
        clock.advance(1)
        vm.resumeCountdown()
        #expect(vm.decisionToken == feedbackToken)
        #expect(vm.decisionStartedAt == feedbackStartedAt)

        // While the leave prompt is open (even with phase == .decision), it also does nothing.
        vm.next()                              // outcome
        vm.nextHand()                          // hand 2, back to .decision
        #expect(vm.phase == .decision)
        #expect(!vm.requestLeave())
        #expect(vm.isConfirmingLeave)
        let promptToken = vm.decisionToken
        let promptStartedAt = vm.decisionStartedAt
        clock.advance(1)
        vm.resumeCountdown()
        #expect(vm.decisionToken == promptToken)
        #expect(vm.decisionStartedAt == promptStartedAt)
    }

    @Test("Discard finishes the session: the countdown can never resume and nothing is saved")
    func discardEndsSession() {
        let vm = makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.hard16vs7])
        vm.choose(.hit)
        #expect(!vm.requestLeave())
        vm.discard()
        #expect(vm.countdownToken == nil)
        #expect(saver.saved.isEmpty)
        // Even a stray call after the view starts closing must not resurrect the countdown or save.
        vm.next()
        vm.nextHand()
        #expect(vm.countdownToken == nil)
        #expect(saver.saved.isEmpty)
        #expect(vm.isFinished)
    }

    @Test("A dealer natural under American peek settles hand 1 at init; hand 2 deals normally")
    func dealerNaturalStart() {
        let vm = makeViewModel(shoes: [[.ten, .ace, .six, .king], StrategyFixtures.hard16vs7])
        #expect(vm.phase == .outcome)
        #expect(vm.allowedActions.isEmpty)
        #expect(vm.countdownToken == nil)
        #expect(vm.requestLeave())            // nothing graded yet; closes at once
        #expect(!vm.isConfirmingLeave)

        vm.nextHand()
        #expect(vm.phase == .decision)
        #expect(vm.handNumber == 2)

        vm.endSession()
        #expect(vm.isFinished)
        #expect(saver.saved.isEmpty)
    }

    @Test("Speed and Weak spots modes show no hint")
    func hintsSpeedAndWeakSpots() {
        #expect(makeViewModel(StrategySessionConfig(mode: .speed), shoes: [StrategyFixtures.hard16vs7]).hint == nil)
        #expect(makeViewModel(StrategySessionConfig(mode: .weakSpots), shoes: [StrategyFixtures.hard16vs7]).hint == nil)
    }

    @Test("Weak spots uses weights only with 50+ decisions of history")
    func weakSpots() {
        #expect(makeViewModel(StrategySessionConfig(mode: .weakSpots), history: history(60)).session.weights != nil)
        #expect(makeViewModel(StrategySessionConfig(mode: .weakSpots), history: history(10)).session.weights == nil)
        #expect(makeViewModel(StrategySessionConfig(mode: .test), history: history(60)).session.weights == nil)
    }

    @Test("WHY opens for the exact hand, upcard and rules")
    func why() throws {
        let vm = makeViewModel(shoes: [StrategyFixtures.eightsVs6])
        vm.choose(.hit)
        vm.showWhy(for: try #require(vm.feedback))
        let context = try #require(vm.presentedWhy)
        #expect(context.handType == .pair)
        #expect(context.pairRank == .eight)
        #expect(context.dealerUpCard == .six)
        #expect(context.userAction == .hit)
        #expect(context.correctAction == .split)
        #expect(context.rules == BlackjackRules())
        #expect(DecisionFeedback.spotTitle(context) == "Pair of 8s vs 6")
    }
}
