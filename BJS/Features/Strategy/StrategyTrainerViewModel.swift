import Foundation
import Observation
import os
import BJSCore

/// One graded decision, kept in memory for feedback, WHY and the summary.
struct GradedDecision: Equatable, Identifiable {
    let id: Int
    let handNumber: Int
    let cell: TrainingCell
    let chosen: RecordedChoice
    let correctAction: Action
    let isCorrect: Bool
    let responseMs: Int
    let decidedAt: Date
    let why: WhyContext
    /// A Speed timeout: the hand is abandoned after this feedback.
    let abandonsHand: Bool

    var draft: DecisionDraft {
        DecisionDraft(handNumber: handNumber, cell: cell, chosen: chosen, correctAction: correctAction,
                      isCorrect: isCorrect, responseMs: responseMs, decidedAt: decidedAt)
    }
}

enum TrainerPhase: Equatable {
    case awaitingDecision
    case feedback(GradedDecision)
    case outcome
    case summary
}

/// The numbers shown on the Strategy session summary screen (spec §5).
struct StrategySessionSummary: Equatable {
    let accuracy: Double?           // nil with no decisions
    let decisionCount: Int
    let mistakes: [GradedDecision]  // in order
    let bestStreak: Int
    let handsPlayed: Int            // hands with at least one decision
    let averageDecisionMs: Double?  // Speed mode only
}

/// Runs a Strategy session over `RoundEngine` (Step 3 spec §4). Thin: BJSCore deals, plays and
/// grades; this type sequences phases, hides the dealer until the outcome, and persists.
@MainActor
@Observable
final class StrategyTrainerViewModel {
    typealias ShoeMaker = (TrainingCell, BlackjackRules, inout SeededRandomNumberGenerator) -> Shoe

    static let defaultShoeMaker: ShoeMaker = { cell, rules, rng in
        HandGenerator.stackedShoe(for: cell, deckCount: rules.deckCount.rawValue,
                                  peekRule: rules.peekRule, using: &rng)
    }
    private static let engine = StrategyEngine()

    let setup: StrategySetup
    let rules: BlackjackRules
    let handLimit: Int?
    let speedTimerSeconds: Double
    let sessionID = UUID()
    let startedAt: Date

    private(set) var phase: TrainerPhase = .awaitingDecision
    private(set) var round: RoundEngine?
    private(set) var handNumber = 0
    private(set) var handsCompleted = 0
    private(set) var decisions: [GradedDecision] = []
    private(set) var decisionToken = 0
    private(set) var decisionStartedAt: Date
    private(set) var toastCount = 0
    private(set) var hasSaved = false
    private(set) var saveFailed = false
    private(set) var endedAt: Date?

    @ObservationIgnored private let table: StrategyTable
    @ObservationIgnored private let weights: [TrainingCell: Double]?
    @ObservationIgnored private var rng: SeededRandomNumberGenerator
    @ObservationIgnored private var shoe = Shoe(orderedCards: [])
    @ObservationIgnored let now: () -> Date
    @ObservationIgnored private let makeShoe: ShoeMaker
    @ObservationIgnored let persist: (SessionDraft) throws -> Void
    @ObservationIgnored let logger = Logger(subsystem: "com.bjs.app", category: "StrategyTrainer")

    init(setup: StrategySetup, rules: BlackjackRules, weights: [TrainingCell: Double]?,
         speedTimerSeconds: Double, handLimitOverride: Int? = nil, seed: UInt64,
         now: @escaping () -> Date = { Date() }, makeShoe: ShoeMaker? = nil,
         persist: @escaping (SessionDraft) throws -> Void) {
        self.setup = setup
        self.rules = rules
        self.handLimit = handLimitOverride ?? setup.length.handLimit
        self.speedTimerSeconds = speedTimerSeconds
        self.weights = setup.mode.usesWeights ? weights : nil
        self.rng = SeededRandomNumberGenerator(seed: seed)
        self.now = now
        if let makeShoe {
            self.makeShoe = makeShoe
        } else {
            self.makeShoe = Self.defaultShoeMaker
        }
        self.persist = persist
        self.table = Self.engine.strategy(for: rules)
        let start = now()
        self.startedAt = start
        self.decisionStartedAt = start
        dealNextHand()
    }

    // MARK: - Display

    var spot: DecisionSpot? { phase == .awaitingDecision ? round?.currentSpot : nil }
    var legalActions: Set<Action> { spot?.legalActions ?? [] }
    var hint: Action? {
        guard setup.mode.showsHint, let spot else { return nil }
        return table.action(for: spot)
    }
    var isDealerRevealed: Bool { phase == .outcome }
    var dealerCards: [Card] {
        guard let round else { return [] }
        return isDealerRevealed ? round.dealer.cards : Array(round.dealer.cards.prefix(2))
    }
    var playerHands: [PlayerHandState] { round?.hands ?? [] }
    var activeHandIndex: Int { round?.activeHandIndex ?? 0 }
    var outcomeLines: [String] {
        guard let round else { return [] }
        return StrategyText.outcomeLines(hands: round.hands, dealer: round.dealer)
    }
    var correctCount: Int { decisions.filter { $0.isCorrect }.count }
    var currentStreak: Int {
        var run = 0
        for d in decisions.reversed() {
            guard d.isCorrect else { break }
            run += 1
        }
        return run
    }

    /// Whether "Save partial" has anything to save right now.
    var canSavePartial: Bool { !decisions.isEmpty && phase != .summary }

    var sessionDraft: SessionDraft {
        SessionDraft(id: sessionID, module: .strategy, mode: setup.mode.rawValue, startedAt: startedAt,
                     endedAt: endedAt ?? now(), rules: rules, decisions: decisions.map { $0.draft })
    }

    var summary: StrategySessionSummary {
        let core = SessionSummary(decisions: decisions.map { ($0.isCorrect, $0.responseMs) }, countChecks: [])
        return StrategySessionSummary(
            accuracy: decisions.isEmpty ? nil : Double(core.correctDecisions) / Double(core.decisionCount),
            decisionCount: core.decisionCount,
            mistakes: decisions.filter { !$0.isCorrect },
            bestStreak: core.bestStreak,
            handsPlayed: Set(decisions.map { $0.handNumber }).count,
            averageDecisionMs: setup.mode.isTimed ? core.meanResponseMs : nil)
    }

    // MARK: - Input

    func choose(_ action: Action) {
        guard phase == .awaitingDecision, var round, let spot = round.currentSpot,
              spot.legalActions.contains(action) else { return }
        let decidedAt = now()
        let correct = table.action(for: spot)
        let graded = GradedDecision(
            id: decisions.count, handNumber: handNumber, cell: TrainingCell(spot: spot),
            chosen: .action(action), correctAction: correct, isCorrect: action == correct,
            responseMs: Self.milliseconds(from: decisionStartedAt, to: decidedAt), decidedAt: decidedAt,
            why: WhyContext(spot: spot, userAction: action, table: table, rules: rules),
            abandonsHand: false)
        decisions.append(graded)
        do {
            try round.apply(action, shoe: &shoe)
        } catch {
            logger.error("RoundEngine rejected \(action.rawValue): \(String(describing: error))")
        }
        self.round = round
        if !graded.isCorrect || round.phase != .playerTurn {
            phase = .feedback(graded)
        } else {
            toastCount += 1
            beginDecision()
        }
    }

    /// FeedbackCard NEXT.
    func next() {
        guard case .feedback(let graded) = phase, let round else { return }
        if graded.abandonsHand {
            completeHand()
        } else if round.phase == .playerTurn {
            beginDecision()
        } else {
            phase = .outcome
        }
    }

    /// Outcome DEAL.
    func deal() {
        guard phase == .outcome else { return }
        completeHand()
    }

    // MARK: - Internals

    private func completeHand() {
        handsCompleted += 1
        if let handLimit, handsCompleted >= handLimit {
            finish()
        } else {
            dealNextHand()
        }
    }

    private func dealNextHand() {
        handNumber += 1
        let cell = HandGenerator.sampleCell(filter: setup.filter, weights: weights, using: &rng)
        shoe = makeShoe(cell, rules, &rng)
        do {
            let fresh = try RoundEngine(rules: rules, shoe: &shoe)
            round = fresh
            if fresh.phase == .settled {
                phase = .outcome
            } else {
                beginDecision()
            }
        } catch {
            logger.error("Could not deal a training hand: \(String(describing: error))")
            finish()
        }
    }

    private func beginDecision() {
        decisionToken += 1
        decisionStartedAt = now()
        phase = .awaitingDecision
    }

    /// Re-arms the current decision's clock, e.g. after the "Leave this session?" dialog closes:
    /// a fresh token means a Speed timeout that was already in flight can't fire for time spent
    /// away from the dock, and the response time for this decision is measured from here rather
    /// than from before the interruption. A no-op outside `.awaitingDecision`.
    func restartDecisionClock() {
        guard phase == .awaitingDecision else { return }
        beginDecision()
    }

    /// Speed mode: the view's timer fired for the decision identified by `token`.
    func timeoutElapsed(token: Int) {
        guard setup.mode.isTimed, phase == .awaitingDecision, token == decisionToken,
              let spot = round?.currentSpot else { return }
        let graded = GradedDecision(
            id: decisions.count, handNumber: handNumber, cell: TrainingCell(spot: spot), chosen: .timeout,
            correctAction: table.action(for: spot), isCorrect: false,
            responseMs: Int((speedTimerSeconds * 1000).rounded()), decidedAt: now(),
            why: WhyContext(spot: spot, userAction: nil, table: table, rules: rules),
            abandonsHand: true)
        decisions.append(graded)
        phase = .feedback(graded)
    }

    /// Ends the session (length reached, END, or Save partial): shows the summary and saves once.
    /// A session with no graded decisions isn't saved.
    func finish() {
        guard phase != .summary else { return }
        endedAt = now()
        phase = .summary
        guard !decisions.isEmpty, !hasSaved else { return }
        hasSaved = true
        do {
            try persist(sessionDraft)
        } catch {
            saveFailed = true
            logger.error("Strategy session failed to save: \(error.localizedDescription)")
        }
    }

    static func milliseconds(from start: Date, to end: Date) -> Int {
        max(0, Int((end.timeIntervalSince(start) * 1000).rounded()))
    }
}
