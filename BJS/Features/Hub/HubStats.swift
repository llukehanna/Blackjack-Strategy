import BJSCore
import Foundation

/// The hub's three stat chips (spec §5 Hub), computed from persisted samples.
///
/// - Strategy accuracy: graded decisions from Strategy and Shoe Sim sessions, last 30 days.
/// - Count accuracy: count checks from Counting (RC and TC) and Shoe Sim sessions, last 30 days.
/// - Streak: consecutive correct decisions, newest first, across all sessions.
struct HubStats: Equatable, Sendable {
    static let windowDays = 30

    let strategyAccuracy: Double?
    let countAccuracy: Double?
    let strategyStreak: Int

    static func make(sessions: [SessionSample], decisions: [DecisionSample], now: Date,
                     calendar: Calendar = .current) -> HubStats {
        let since = calendar.date(byAdding: .day, value: -windowDays, to: now) ?? now
        let strategy = ProgressStats.headline(sessions: sessions, modules: [.strategy, .shoe],
                                              measure: .decisions, since: since)
        let count = ProgressStats.headline(sessions: sessions, modules: [.countingRC, .countingTC, .shoe],
                                           measure: .countChecks, since: since)
        return HubStats(strategyAccuracy: strategy.accuracy, countAccuracy: count.accuracy,
                        strategyStreak: ProgressStats.currentStreak(decisions))
    }

    /// "87%", or "—" with no data.
    static func percentText(_ accuracy: Double?) -> String {
        guard let accuracy else { return "—" }
        return "\(Int((accuracy * 100).rounded()))%"
    }
}
