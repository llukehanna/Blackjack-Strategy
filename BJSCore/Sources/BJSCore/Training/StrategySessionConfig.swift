/// Strategy trainer modes (spec §5 Strategy).
public enum StrategyMode: String, CaseIterable, Sendable, Codable {
    /// The correct action carries the brass hint ring before the user chooses.
    case learn
    /// No hints.
    case test
    /// No hints; a countdown per decision. A timeout is an incorrect decision.
    case speed
    /// As Test, but hands are sampled by `WeakSpotWeights`.
    case weakSpots

    /// Learn mode shows the correct action before the user chooses.
    public var showsHint: Bool { self == .learn }

    /// Speed mode runs a countdown per decision.
    public var isTimed: Bool { self == .speed }

    /// Weak-spots mode samples hands by weight.
    public var usesWeakSpotWeights: Bool { self == .weakSpots }
}

/// How many hands a strategy session deals.
public enum StrategySessionLength: String, CaseIterable, Sendable, Codable {
    case hands25
    case hands50
    case hands100
    case endless

    /// nil for Endless.
    public var handLimit: Int? {
        switch self {
        case .hands25: return 25
        case .hands50: return 50
        case .hands100: return 100
        case .endless: return nil
        }
    }
}

/// Everything the Strategy setup screen chooses. Also stored as the hub's `lastLaunch` setup.
public struct StrategySessionConfig: Sendable, Hashable, Codable {
    public var mode: StrategyMode
    public var length: StrategySessionLength
    public var filter: HandFilter

    public init(mode: StrategyMode = .learn, length: StrategySessionLength = .hands25, filter: HandFilter = .all) {
        self.mode = mode
        self.length = length
        self.filter = filter
    }
}
