import Foundation
import Observation
import BJSCore

/// Maps progress samples to the hub's stat chip strings.
@Observable
final class HubViewModel {
    static let accuracyWindowDays = 30
    static let strategyModules: Set<TrainingModule> = [.strategy, .shoe]
    static let countModules: Set<TrainingModule> = [.countingRC, .countingTC, .shoe]
    static let noData = "—"

    private(set) var strategyAccuracy = noData
    private(set) var countAccuracy = noData
    private(set) var streak = noData

    /// - Parameter decisions: strategy and shoe decisions, chronological.
    func update(sessions: [SessionSample], decisions: [DecisionSample], now: Date,
                calendar: Calendar = .current) {
        let since = calendar.date(byAdding: .day, value: -Self.accuracyWindowDays, to: now)
        strategyAccuracy = Self.percent(ProgressStats.headline(
            sessions: sessions, modules: Self.strategyModules, measure: .decisions, since: since).accuracy)
        countAccuracy = Self.percent(ProgressStats.headline(
            sessions: sessions, modules: Self.countModules, measure: .countChecks, since: since).accuracy)
        streak = decisions.isEmpty ? Self.noData : String(ProgressStats.currentStreak(decisions))
    }

    static func percent(_ fraction: Double?) -> String {
        guard let fraction else { return noData }
        return "\(Int((fraction * 100).rounded()))%"
    }
}
