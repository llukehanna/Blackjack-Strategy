/// Scores for a finished RC or TC drill (Step 4 spec §3).
public struct CountDrillScore: Sendable, Equatable {
    public let checks: Int
    public let correct: Int
    /// Fraction of checks graded correct; nil with no checks.
    public let accuracy: Double?
    /// Mean of |answered − expected|; nil with no checks.
    public let meanAbsoluteError: Double?

    public init(_ results: [(expected: Double, answered: Double, isCorrect: Bool)]) {
        checks = results.count
        correct = results.filter { $0.isCorrect }.count
        accuracy = results.isEmpty ? nil : Double(correct) / Double(checks)
        meanAbsoluteError = results.isEmpty ? nil
            : results.reduce(0) { $0 + abs($1.answered - $1.expected) } / Double(checks)
    }

    /// How long each card was on screen in an RC drill.
    public static func secondsPerCard(pace: Double, groupSize: Int) -> Double {
        pace / Double(max(1, groupSize))
    }
}
