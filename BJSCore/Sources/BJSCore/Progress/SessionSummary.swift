/// The cached summary stored on each saved session.
public struct SessionSummary: Sendable, Equatable {
    public let decisionCount: Int
    public let correctDecisions: Int
    public let countCheckCount: Int
    public let correctCountChecks: Int
    /// Longest run of consecutive correct decisions, in the order given.
    public let bestStreak: Int
    /// Mean response time over decisions that recorded one; nil if none did.
    public let meanResponseMs: Double?

    public init(decisions: [(isCorrect: Bool, responseMs: Int?)], countChecks: [Bool]) {
        decisionCount = decisions.count
        correctDecisions = decisions.filter(\.isCorrect).count
        countCheckCount = countChecks.count
        correctCountChecks = countChecks.filter { $0 }.count

        var best = 0, run = 0
        for d in decisions {
            run = d.isCorrect ? run + 1 : 0
            best = max(best, run)
        }
        bestStreak = best

        let times = decisions.compactMap(\.responseMs)
        meanResponseMs = times.isEmpty ? nil : Double(times.reduce(0, +)) / Double(times.count)
    }
}
