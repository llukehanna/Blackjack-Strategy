/// Rule contribution to house edge.
public struct RuleContribution: Sendable {
    public let rule: String
    public let delta: Double

    public init(rule: String, delta: Double) {
        self.rule = rule
        self.delta = delta
    }
}

/// Result of edge analysis for a rule set.
public struct EdgeAnalysis: Sendable {
    public let houseEdge: Double
    public let contributions: [RuleContribution]

    public init(houseEdge: Double, contributions: [RuleContribution]) {
        self.houseEdge = houseEdge
        self.contributions = contributions
    }
}

/// Calculates house edge using WoO rule-effect delta approach.
///
/// Stub implementation -- will be replaced by plan 01-03.
public final class EdgeCalculator: Sendable {

    /// Baseline house edge: 8D S17 DAS, no surrender, 3:2, peek, any-two doubles.
    public static let baselineHouseEdge: Double = 0.43

    public init() {}

    /// Analyze the house edge for the given rules.
    public func analyze(rules: BlackjackRules) -> EdgeAnalysis {
        var contributions: [RuleContribution] = []
        var edge = Self.baselineHouseEdge

        // Deck count
        switch rules.deckCount {
        case .one: contributions.append(.init(rule: "Single deck", delta: 0.48)); edge -= 0.48
        case .two: contributions.append(.init(rule: "Double deck", delta: 0.19)); edge -= 0.19
        case .four: contributions.append(.init(rule: "4 decks", delta: 0.06)); edge -= 0.06
        case .six: contributions.append(.init(rule: "6 decks", delta: 0.02)); edge -= 0.02
        case .eight: break // baseline
        }

        // Dealer soft 17
        if rules.dealerSoft17 == .hits {
            contributions.append(.init(rule: "Dealer hits soft 17", delta: -0.22))
            edge += 0.22
        }

        // DAS
        if !rules.doubleAfterSplit {
            contributions.append(.init(rule: "No DAS", delta: -0.14))
            edge += 0.14
        }

        // RSA
        if rules.resplitAces {
            contributions.append(.init(rule: "Resplit aces", delta: 0.08))
            edge -= 0.08
        }

        // Hit split aces
        if rules.hitSplitAces {
            contributions.append(.init(rule: "Hit split aces", delta: 0.19))
            edge -= 0.19
        }

        // Surrender
        switch rules.surrenderRule {
        case .none: break
        case .late: contributions.append(.init(rule: "Late surrender", delta: 0.08)); edge -= 0.08
        case .early: contributions.append(.init(rule: "Early surrender", delta: 0.24)); edge -= 0.24
        }

        // Double restriction
        switch rules.doubleRestriction {
        case .anyTwo: break
        case .nineToEleven: contributions.append(.init(rule: "Double 9-11 only", delta: -0.09)); edge += 0.09
        case .tenToEleven: contributions.append(.init(rule: "Double 10-11 only", delta: -0.18)); edge += 0.18
        }

        // Peek
        if rules.peekRule == .europeanNoPeek {
            contributions.append(.init(rule: "ENHC", delta: -0.11))
            edge += 0.11
        }

        // BJ payout
        switch rules.blackjackPayout {
        case .threeToTwo: break
        case .sixToFive: contributions.append(.init(rule: "BJ pays 6:5", delta: -1.39)); edge += 1.39
        case .twoToOne: contributions.append(.init(rule: "BJ pays 2:1", delta: 0.32)); edge -= 0.32
        }

        // Max split hands
        switch rules.maxSplitHands {
        case 2: contributions.append(.init(rule: "Split to 2 hands max", delta: -0.10)); edge += 0.10
        case 3: contributions.append(.init(rule: "Split to 3 hands max", delta: -0.01)); edge += 0.01
        default: break // 4 is baseline
        }

        return EdgeAnalysis(houseEdge: edge, contributions: contributions)
    }

    /// Convenience: returns just the house edge percentage.
    public func houseEdge(for rules: BlackjackRules) -> Double {
        return analyze(rules: rules).houseEdge
    }
}
