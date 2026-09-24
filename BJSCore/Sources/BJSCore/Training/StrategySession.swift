import Foundation

public enum StrategySessionError: Error, Equatable, Sendable {
    /// The call does not fit the session's current phase (e.g. a second tap on STAND).
    case wrongPhase
    /// The action is not legal at the current decision.
    case illegalAction(Action)
}

/// One Strategy-trainer session as a pure value-type state machine (spec §5 Strategy).
///
/// Every hand is dealt from a fresh stacked shoe (`HandGenerator`, honouring the filter and,
/// in Weak-spots mode, the weights) and played through `RoundEngine`, including splits.
/// Each decision is graded against the `StrategyTable` for the session's rules:
///
///     decision ──choose──▶ feedback ──continueAfterFeedback──▶ decision (same hand)
///                                                          └─▶ outcome ──nextHand──▶ decision (next hand)
///                                                                               └─▶ finished (hand limit)
///     any phase ──finish──▶ finished
///
/// The graded action is applied to the round only when the feedback is dismissed, so the
/// FeedbackCard always appears before the hand's outcome is revealed. After a timeout the
/// correct action is played, so the hand continues along the right line.
public struct StrategySession: Sendable {

    public enum Phase: Sendable, Equatable {
        /// Waiting for the player's action at `currentSpot`.
        case decision
        /// A decision has been graded (`lastDecision`); its action is not yet applied.
        case feedback
        /// The hand is settled: the dealer's hand and the outcomes are visible.
        case outcome
        /// The session is over.
        case finished
    }

    /// Where hands come from.
    public enum HandSource: Sendable {
        /// `HandGenerator`: a sampled cell, stacked into a fresh shoe of the rules' deck count.
        case generated
        /// These shoes in order, cycling. For tests (spec §7: "fake shoe"). Must not be empty.
        case scripted([Shoe])
    }

    public let rules: BlackjackRules
    public let config: StrategySessionConfig
    /// The sampling weights in use: non-nil only in Weak-spots mode with enough history.
    public let weights: [TrainingCell: Double]?
    public private(set) var phase: Phase
    public private(set) var round: RoundEngine
    /// 1-based number of the hand on the table.
    public private(set) var handNumber: Int
    /// Hands that reached settlement.
    public private(set) var handsCompleted: Int
    public private(set) var decisions: [GradedDecision] = []

    private let table: StrategyTable
    private let source: HandSource
    private var shoe: Shoe
    private var scriptIndex: Int
    /// The action `continueAfterFeedback()` applies.
    private var pendingAction: Action?

    public init<G: RandomNumberGenerator>(rules: BlackjackRules, config: StrategySessionConfig,
                                          table: StrategyTable, weights: [TrainingCell: Double]? = nil,
                                          source: HandSource = .generated, using rng: inout G) throws {
        self.rules = rules
        self.config = config
        self.table = table
        self.weights = config.mode.usesWeakSpotWeights ? weights : nil
        self.source = source
        var shoe = Self.makeShoe(source: source, scriptIndex: 0, rules: rules, config: config,
                                 weights: self.weights, using: &rng)
        self.round = try RoundEngine(rules: rules, shoe: &shoe)
        self.shoe = shoe
        self.scriptIndex = 1
        self.handNumber = 1
        let settled = round.phase == .settled
        self.handsCompleted = settled ? 1 : 0
        self.phase = settled ? .outcome : .decision
    }

    // MARK: - Queries

    /// The decision on the table, only in the `.decision` phase.
    public var currentSpot: DecisionSpot? {
        phase == .decision ? round.currentSpot : nil
    }

    /// Basic strategy's action at `currentSpot`.
    public var correctAction: Action? {
        currentSpot.map { table.action(for: $0) }
    }

    /// Learn mode's brass-ring action; nil in every other mode.
    public var hint: Action? {
        config.mode.showsHint ? correctAction : nil
    }

    /// The decision most recently graded (the FeedbackCard's subject in `.feedback`).
    public var lastDecision: GradedDecision? { decisions.last }

    /// True when the hand on the table is the last one the length allows.
    public var isLastHand: Bool {
        guard let limit = config.length.handLimit else { return false }
        return handNumber >= limit
    }

    public var summary: StrategySessionSummary {
        StrategySessionSummary(decisions: decisions, handsPlayed: handsCompleted)
    }

    // MARK: - Transitions

    /// Grades the player's choice at `currentSpot`. The session moves to `.feedback`.
    @discardableResult
    public mutating func choose(_ choice: DecisionChoice, responseMs: Int?, at date: Date) throws -> GradedDecision {
        guard phase == .decision, let spot = round.currentSpot else { throw StrategySessionError.wrongPhase }
        if let action = choice.action, !spot.legalActions.contains(action) {
            throw StrategySessionError.illegalAction(action)
        }
        let correct = table.action(for: spot)
        let decision = GradedDecision(sequence: decisions.count + 1, handNumber: handNumber, spot: spot,
                                      choice: choice, correctAction: correct, responseMs: responseMs,
                                      decidedAt: date)
        decisions.append(decision)
        pendingAction = choice.action ?? correct
        phase = .feedback
        return decision
    }

    /// NEXT on the FeedbackCard: plays the graded action (the correct one after a timeout).
    /// Moves to the next decision of this hand, or to `.outcome` when the hand settles.
    public mutating func continueAfterFeedback() throws {
        guard phase == .feedback, let action = pendingAction else { throw StrategySessionError.wrongPhase }
        pendingAction = nil
        try round.apply(action, shoe: &shoe)
        if round.phase == .settled {
            handsCompleted += 1
            phase = .outcome
        } else {
            phase = .decision
        }
    }

    /// Deals the next hand from a fresh shoe, or finishes the session after the last hand.
    public mutating func nextHand<G: RandomNumberGenerator>(using rng: inout G) throws {
        guard phase == .outcome else { throw StrategySessionError.wrongPhase }
        if isLastHand {
            phase = .finished
            return
        }
        var shoe = Self.makeShoe(source: source, scriptIndex: scriptIndex, rules: rules, config: config,
                                 weights: weights, using: &rng)
        round = try RoundEngine(rules: rules, shoe: &shoe)
        self.shoe = shoe
        scriptIndex += 1
        handNumber += 1
        pendingAction = nil
        if round.phase == .settled {
            handsCompleted += 1
            phase = .outcome
        } else {
            phase = .decision
        }
    }

    /// Ends the session now (Endless "End", or Save partial). Graded decisions are kept;
    /// an unfinished hand does not count as played.
    public mutating func finish() {
        pendingAction = nil
        phase = .finished
    }

    // MARK: - Dealing

    private static func makeShoe<G: RandomNumberGenerator>(
        source: HandSource, scriptIndex: Int, rules: BlackjackRules, config: StrategySessionConfig,
        weights: [TrainingCell: Double]?, using rng: inout G
    ) -> Shoe {
        switch source {
        case .generated:
            let cell = HandGenerator.sampleCell(filter: config.filter, weights: weights, using: &rng)
            return HandGenerator.stackedShoe(for: cell, deckCount: rules.deckCount.rawValue, using: &rng)
        case .scripted(let shoes):
            precondition(!shoes.isEmpty, "StrategySession.HandSource.scripted needs at least one shoe")
            return shoes[scriptIndex % shoes.count]
        }
    }
}
