/// A strategy session's summary numbers (spec §5 Summary) and the cached values
/// stored on its `Session` (spec §6).
public struct StrategySessionSummary: Sendable, Equatable {
    public let decisionCount: Int
    public let correctDecisions: Int
    /// Longest run of consecutive correct decisions in this session.
    public let bestStreak: Int
    /// Hands that reached settlement.
    public let handsPlayed: Int
    /// Mean reaction time over decisions that recorded one, or nil if none did.
    public let meanResponseMs: Double?
    /// Incorrect decisions (including timeouts), in the order they were made.
    public let mistakes: [GradedDecision]

    public init(decisions: [GradedDecision], handsPlayed: Int) {
        let ordered = decisions.sorted { $0.sequence < $1.sequence }
        decisionCount = ordered.count
        correctDecisions = ordered.filter(\.isCorrect).count
        bestStreak = Self.bestStreak(ordered)
        self.handsPlayed = handsPlayed
        let times = ordered.compactMap(\.responseMs)
        meanResponseMs = times.isEmpty ? nil : Double(times.reduce(0, +)) / Double(times.count)
        mistakes = ordered.filter { !$0.isCorrect }
    }

    public var mistakeCount: Int { mistakes.count }

    /// Fraction correct in 0...1, or nil with no decisions.
    public var accuracy: Double? {
        decisionCount == 0 ? nil : Double(correctDecisions) / Double(decisionCount)
    }

    /// Longest run of consecutive correct decisions, in the given order.
    public static func bestStreak(_ decisions: [GradedDecision]) -> Int {
        var best = 0
        var run = 0
        for decision in decisions {
            run = decision.isCorrect ? run + 1 : 0
            best = max(best, run)
        }
        return best
    }
}
