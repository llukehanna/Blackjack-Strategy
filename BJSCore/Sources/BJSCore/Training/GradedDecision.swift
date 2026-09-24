import Foundation

/// What the player did at a decision: an action, or nothing before the Speed-mode countdown ran out.
public enum DecisionChoice: Sendable, Hashable {
    case action(Action)
    case timeout

    /// The string stored in `DecisionRecord.chosenAction` for a timeout.
    public static let timeoutStorageValue = "timeout"

    /// `Action` raw value, or "timeout".
    public var storageValue: String {
        switch self {
        case .action(let action): return action.rawValue
        case .timeout: return Self.timeoutStorageValue
        }
    }

    /// The chosen action, or nil for a timeout.
    public var action: Action? {
        switch self {
        case .action(let action): return action
        case .timeout: return nil
        }
    }
}

/// One strategy decision, graded against the basic-strategy table for the session's rules.
public struct GradedDecision: Sendable, Equatable, Identifiable {
    /// 1-based position of this decision in its session. Also the `id`.
    public let sequence: Int
    /// 1-based hand number within the session.
    public let handNumber: Int
    public let spot: DecisionSpot
    /// The heat-map / weak-spot cell (`TrainingCell(spot:)`).
    public let cell: TrainingCell
    public let choice: DecisionChoice
    public let correctAction: Action
    /// Reaction time in milliseconds. For a timeout, the full countdown.
    public let responseMs: Int?
    /// When the decision was made. Persisted as `DecisionRecord.decidedAt`.
    public let decidedAt: Date

    public var id: Int { sequence }

    public var isCorrect: Bool { choice == .action(correctAction) }

    public init(sequence: Int, handNumber: Int, spot: DecisionSpot, choice: DecisionChoice,
                correctAction: Action, responseMs: Int?, decidedAt: Date) {
        self.sequence = sequence
        self.handNumber = handNumber
        self.spot = spot
        self.cell = TrainingCell(spot: spot)
        self.choice = choice
        self.correctAction = correctAction
        self.responseMs = responseMs
        self.decidedAt = decidedAt
    }

    /// The WHY-sheet context for this decision. A timeout is explained as if the
    /// correct action had been chosen (the explanation only depends on the correct action).
    public func whyContext(rules: BlackjackRules) -> WhyContext {
        WhyContext(spot: spot, userAction: choice.action ?? correctAction,
                   correctAction: correctAction, rules: rules)
    }
}

extension WhyContext {
    /// Builds the explanation context for a decision spot. The hand type follows
    /// `TrainingCell(spot:)`: a pair counts as a pair only while splitting is legal;
    /// otherwise it is explained by its hard or soft total (e.g. A,A → soft 12).
    public init(id: UUID = UUID(), spot: DecisionSpot, userAction: Action, correctAction: Action,
                rules: BlackjackRules) {
        let cell = TrainingCell(spot: spot)
        self.init(id: id,
                  handTotal: spot.hand.total,
                  handType: cell.handType,
                  pairRank: cell.handType == .pair ? spot.hand.cards[0].rank : nil,
                  dealerUpCard: spot.dealerUpcard,
                  userAction: userAction,
                  correctAction: correctAction,
                  rules: rules)
    }
}
