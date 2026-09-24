import BJSCore
import Foundation

/// Everything persisted for one finished (or partially saved) Strategy session.
struct StrategySessionSnapshot: Sendable, Equatable {
    let id: UUID
    let config: StrategySessionConfig
    /// The rules the session ran under (its snapshot of the active rules).
    let rules: BlackjackRules
    let startedAt: Date
    let endedAt: Date
    let summary: StrategySessionSummary
    let decisions: [GradedDecision]
}

/// Saves Strategy sessions. The app uses `SwiftDataStrategySessionSaver`; ViewModel tests use a fake.
@MainActor
protocol StrategySessionSaving {
    func save(_ snapshot: StrategySessionSnapshot) throws
}
