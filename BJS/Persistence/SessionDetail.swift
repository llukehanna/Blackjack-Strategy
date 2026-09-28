import Foundation
import BJSCore

/// A history row's data: the session's cached summary plus its mode (Step 6 spec §5).
struct HistoryEntry: Equatable, Identifiable {
    let sample: SessionSample
    let mode: String?
    var id: UUID { sample.id }
}

/// One saved session with its records, for the read-only session detail (Step 6 spec §3, §5).
struct SessionDetail: Equatable {
    struct Decision: Equatable {
        let cell: TrainingCell
        let chosen: RecordedChoice
        let correctAction: Action
        let isCorrect: Bool
        let responseMs: Int?
    }

    struct Check: Equatable {
        let sample: CountSample
        let cardsSeen: Int
    }

    let sample: SessionSample
    let mode: String?
    let rules: BlackjackRules
    let bestStreak: Int
    let meanResponseMs: Double?
    /// In the order they happened.
    let decisions: [Decision]
    /// In the order they happened.
    let checks: [Check]
}
