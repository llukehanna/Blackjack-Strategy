/// Result of one player hand after the round settles.
public enum HandOutcome: String, Sendable, Equatable, Codable {
    case blackjack, win, push, loss, bust, surrendered
}

/// One player hand inside a round. A round holds several after splits.
public struct PlayerHandState: Sendable, Equatable {
    public internal(set) var hand: BlackjackHand
    public internal(set) var isDoubled = false
    public internal(set) var isSurrendered = false
    /// True when this hand was created by splitting.
    public internal(set) var isFromSplit = false
    /// True when this hand was created by splitting aces.
    public internal(set) var isSplitAces = false
    public internal(set) var isFinished = false
    public internal(set) var outcome: HandOutcome?
    /// Net result in units of the initial bet (e.g. +1.5 for a 3:2 blackjack, -2 for a lost double).
    public internal(set) var net: Double = 0

    /// Units at risk on this hand.
    public var betUnits: Double { isDoubled ? 2 : 1 }

    init(hand: BlackjackHand) {
        self.hand = hand
    }
}

public enum RoundError: Error, Equatable, Sendable {
    case shoeExhausted
    case illegalAction(Action)
    case notPlayerTurn
}

/// Everything needed to grade one player decision.
public struct DecisionSpot: Sendable, Equatable {
    public let hand: BlackjackHand
    public let dealerUpcard: Rank
    public let legalActions: Set<Action>

    public init(hand: BlackjackHand, dealerUpcard: Rank, legalActions: Set<Action>) {
        self.hand = hand
        self.dealerUpcard = dealerUpcard
        self.legalActions = legalActions
    }
}

extension BlackjackRules.BlackjackPayout {
    /// Units won on a natural for a one-unit bet.
    public var multiplier: Double {
        switch self {
        case .threeToTwo: return 1.5
        case .sixToFive: return 1.2
        case .twoToOne: return 2.0
        }
    }
}

extension StrategyTable {
    /// The correct (legal) action for a decision spot.
    public func action(for spot: DecisionSpot) -> Action {
        action(for: spot.hand, dealerUpcard: spot.dealerUpcard, legal: spot.legalActions)
    }
}
