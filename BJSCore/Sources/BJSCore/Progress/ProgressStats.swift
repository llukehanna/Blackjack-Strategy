import Foundation

public struct Headline: Sendable, Equatable {
    public let attempts: Int
    public let correct: Int

    public init(attempts: Int, correct: Int) {
        self.attempts = attempts
        self.correct = correct
    }

    /// Fraction correct in 0...1, or nil with no attempts.
    public var accuracy: Double? {
        attempts == 0 ? nil : Double(correct) / Double(attempts)
    }
}

public struct TrendPoint: Sendable, Equatable {
    /// Start of the calendar day.
    public let day: Date
    public let attempts: Int
    public let correct: Int

    public var accuracy: Double { Double(correct) / Double(attempts) }
}

public struct HeatCell: Sendable, Equatable {
    public let attempts: Int
    public let errors: Int
    /// nil when there are fewer than `ProgressStats.heatMapMinimumSamples` attempts.
    public let errorRate: Double?

    public init(attempts: Int, errors: Int, errorRate: Double?) {
        self.attempts = attempts
        self.errors = errors
        self.errorRate = errorRate
    }
}

/// Pure aggregation over persisted samples for the hub and the Progress tab.
public enum ProgressStats {

    public enum Measure: Sendable {
        case decisions
        case countChecks
        case combined
    }

    public static let heatMapMinimumSamples = 3

    public static func headline(sessions: [SessionSample], modules: Set<TrainingModule>,
                                measure: Measure, since: Date?) -> Headline {
        let totals = filtered(sessions, modules: modules, since: since).map { tally($0, measure) }
        return Headline(attempts: totals.reduce(0) { $0 + $1.attempts },
                        correct: totals.reduce(0) { $0 + $1.correct })
    }

    public static func dailyTrend(sessions: [SessionSample], modules: Set<TrainingModule>,
                                  measure: Measure, since: Date?, calendar: Calendar) -> [TrendPoint] {
        var byDay: [Date: (attempts: Int, correct: Int)] = [:]
        for session in filtered(sessions, modules: modules, since: since) {
            let day = calendar.startOfDay(for: session.startedAt)
            let t = tally(session, measure)
            let current = byDay[day] ?? (0, 0)
            byDay[day] = (current.attempts + t.attempts, current.correct + t.correct)
        }
        return byDay
            .filter { $0.value.attempts > 0 }
            .map { TrendPoint(day: $0.key, attempts: $0.value.attempts, correct: $0.value.correct) }
            .sorted { $0.day < $1.day }
    }

    public static func heatMap(_ decisions: [DecisionSample]) -> [TrainingCell: HeatCell] {
        var attempts: [TrainingCell: Int] = [:]
        var errors: [TrainingCell: Int] = [:]
        for d in decisions {
            attempts[d.cell, default: 0] += 1
            if !d.isCorrect { errors[d.cell, default: 0] += 1 }
        }
        var result: [TrainingCell: HeatCell] = [:]
        for (cell, a) in attempts {
            let e = errors[cell] ?? 0
            let rate: Double? = a >= heatMapMinimumSamples ? Double(e) / Double(a) : nil
            result[cell] = HeatCell(attempts: a, errors: e, errorRate: rate)
        }
        return result
    }

    /// Consecutive correct decisions counting back from the newest.
    ///
    /// Decisions from a single session often share the same `date`; the caller
    /// always passes `decisions` in chronological order, so ties are broken by
    /// input position (later position = more recent), not left to sort stability.
    public static func currentStreak(_ decisions: [DecisionSample]) -> Int {
        let newestFirst = decisions.enumerated().sorted { a, b in
            if a.element.date != b.element.date { return a.element.date > b.element.date }
            return a.offset > b.offset
        }
        var streak = 0
        for (_, d) in newestFirst {
            guard d.isCorrect else { break }
            streak += 1
        }
        return streak
    }

    // MARK: - Helpers

    private static func filtered(_ sessions: [SessionSample], modules: Set<TrainingModule>,
                                 since: Date?) -> [SessionSample] {
        sessions.filter { modules.contains($0.module) && (since == nil || $0.startedAt >= since!) }
    }

    private static func tally(_ s: SessionSample, _ measure: Measure) -> (attempts: Int, correct: Int) {
        switch measure {
        case .decisions: return (s.decisionCount, s.correctDecisions)
        case .countChecks: return (s.countChecks, s.correctCountChecks)
        case .combined: return (s.decisionCount + s.countChecks, s.correctDecisions + s.correctCountChecks)
        }
    }
}
