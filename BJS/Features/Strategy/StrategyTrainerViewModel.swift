import BJSCore
import Foundation
import Observation

/// Drives one Strategy session for `StrategyTrainerView` (spec §5 Strategy; §3 rule 2).
///
/// A thin adapter over `BJSCore.StrategySession`, which holds all the game logic. This class
/// owns what the engine should not: the random-number generator, the clock (reaction times
/// and each decision's `decidedAt`), the Speed-mode countdown token, the WHY sheet, the
/// leave prompt, and saving.
@MainActor
@Observable
final class StrategyTrainerViewModel {
    /// One engine for the app, so each rule set's table is generated once.
    nonisolated static let strategyEngine = StrategyEngine()

    let config: StrategySessionConfig
    /// The session's snapshot of the active rules.
    let rules: BlackjackRules
    let speedTimerSeconds: Double
    let startedAt: Date

    private(set) var session: StrategySession
    /// Changes whenever a new decision starts. The view restarts the Speed countdown on it.
    private(set) var decisionToken = 0
    /// When the current decision started; reaction time is measured from here.
    private(set) var decisionStartedAt: Date
    /// The WHY sheet's content while it is open.
    var presentedWhy: WhyContext?
    /// The Save partial / Discard prompt.
    var isConfirmingLeave = false
    /// Non-blocking "couldn't save" alert (spec §6). The summary still shows.
    var isShowingSaveError = false
    private(set) var isSaved = false

    @ObservationIgnored private var rng: SeededRandomNumberGenerator
    @ObservationIgnored private var hasCompleted = false
    private let saver: any StrategySessionSaving
    private let now: @MainActor () -> Date
    private let sessionID = UUID()

    /// - Parameters:
    ///   - history: recent decisions for Weak-spots weights (ignored in the other modes).
    ///   - seed: the session's random seed (UI tests pass a fixed one).
    ///   - source: `.generated` in the app; tests may script the shoes.
    init(config: StrategySessionConfig, rules: BlackjackRules, speedTimerSeconds: Double,
         history: [DecisionSample], seed: UInt64, source: StrategySession.HandSource = .generated,
         saver: any StrategySessionSaving, now: @escaping @MainActor () -> Date = { Date() }) {
        self.config = config
        self.rules = rules
        self.speedTimerSeconds = speedTimerSeconds
        self.saver = saver
        self.now = now
        var rng = SeededRandomNumberGenerator(seed: seed)
        let weights = config.mode.usesWeakSpotWeights ? WeakSpotWeights.compute(from: history) : nil
        do {
            session = try StrategySession(rules: rules, config: config,
                                          table: Self.strategyEngine.strategy(for: rules),
                                          weights: weights, source: source, using: &rng)
        } catch {
            // A training shoe holds at least a full deck; dealing four cards cannot run out.
            preconditionFailure("Could not deal the first training hand: \(error)")
        }
        self.rng = rng
        let start = now()
        startedAt = start
        decisionStartedAt = start
    }

    // MARK: - What the view shows

    var phase: StrategySession.Phase { session.phase }
    var isFinished: Bool { session.phase == .finished }
    var handNumber: Int { session.handNumber }

    /// Enabled dock buttons: the legal actions during a decision, none otherwise.
    var allowedActions: Set<Action> { session.currentSpot?.legalActions ?? [] }

    /// Learn mode's brass ring.
    var hint: Action? { session.hint }

    /// The FeedbackCard's decision, only while feedback shows.
    var feedback: GradedDecision? { session.phase == .feedback ? session.lastDecision : nil }

    var summary: StrategySessionSummary { session.summary }

    var dealerHand: BlackjackHand { session.round.dealer }
    var playerHands: [PlayerHandState] { session.round.hands }
    var activeHandIndex: Int { session.round.activeHandIndex }

    /// The hole card stays face down until the hand's outcome.
    var isDealerRevealed: Bool { session.phase == .outcome }

    /// Non-nil while a Speed-mode countdown should run (a decision, no prompt open).
    var countdownToken: Int? {
        guard config.mode.isTimed, session.phase == .decision, !isConfirmingLeave else { return nil }
        return decisionToken
    }

    // MARK: - Player input

    func choose(_ action: Action) {
        grade(.action(action), responseMs: nil)
    }

    /// Speed mode: the countdown for `token` ran out. Stale tokens are ignored.
    func timeExpired(token: Int) {
        guard config.mode.isTimed, token == decisionToken, session.phase == .decision, !isConfirmingLeave else {
            return
        }
        grade(.timeout, responseMs: Int((speedTimerSeconds * 1_000).rounded()))
    }

    /// NEXT on the FeedbackCard.
    func next() {
        guard session.phase == .feedback else { return }
        do {
            try session.continueAfterFeedback()
        } catch {
            endAfterEngineError()
            return
        }
        if session.phase == .decision { startDecision() }
    }

    /// "Next hand" (or "Finish" on the last hand) after the outcome.
    func nextHand() {
        guard session.phase == .outcome else { return }
        do {
            try session.nextHand(using: &rng)
        } catch {
            endAfterEngineError()
            return
        }
        switch session.phase {
        case .decision: startDecision()
        case .finished: completeSession()
        case .feedback, .outcome: break
        }
    }

    /// Endless mode's End button: finish now and show the summary.
    func endSession() {
        guard !isFinished else { return }
        session.finish()
        completeSession()
    }

    // MARK: - Leaving

    /// The close button. Returns true when the view should close right away: on the summary,
    /// or before any decision was graded (there is nothing to save). Otherwise it opens the
    /// Save partial / Discard prompt and returns false.
    func requestLeave() -> Bool {
        if isFinished || session.decisions.isEmpty { return true }
        isConfirmingLeave = true
        return false
    }

    /// "Save partial": ends the session here, saves it, and shows its summary.
    func savePartial() {
        isConfirmingLeave = false
        endSession()
    }

    /// "Keep playing": back to the table. A Speed countdown starts again from full.
    func keepPlaying() {
        isConfirmingLeave = false
        if session.phase == .decision { startDecision() }
    }

    /// "Discard": nothing is saved; the view closes.
    func discard() {
        isConfirmingLeave = false
    }

    // MARK: - WHY

    func showWhy(for decision: GradedDecision) {
        presentedWhy = decision.whyContext(rules: rules)
    }

    // MARK: - Internals

    private func grade(_ choice: DecisionChoice, responseMs: Int?) {
        guard session.phase == .decision else { return }        // double taps, late timeouts
        let date = now()
        let elapsed = Int((date.timeIntervalSince(decisionStartedAt) * 1_000).rounded())
        do {
            try session.choose(choice, responseMs: responseMs ?? max(0, elapsed), at: date)
        } catch {
            // Illegal actions cannot be tapped (the dock dims them); ignore defensively.
        }
    }

    private func startDecision() {
        decisionToken += 1
        decisionStartedAt = now()
    }

    /// The engine cannot fail with a stacked training shoe; if it ever does, end the session
    /// gracefully with what was graded so far.
    private func endAfterEngineError() {
        session.finish()
        completeSession()
    }

    private func completeSession() {
        guard !hasCompleted else { return }
        hasCompleted = true
        // Nothing was graded (e.g. Endless End tapped immediately): the summary still shows
        // (all zeros), but there is nothing worth writing to the store.
        guard !session.decisions.isEmpty else { return }
        let snapshot = StrategySessionSnapshot(id: sessionID, config: config, rules: rules, startedAt: startedAt,
                                               endedAt: now(), summary: session.summary,
                                               decisions: session.decisions)
        do {
            try saver.save(snapshot)
            isSaved = true
        } catch {
            isShowingSaveError = true
        }
    }
}
