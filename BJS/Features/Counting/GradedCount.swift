import Foundation
import BJSCore

/// One graded count check, kept in memory for feedback, WHY and the summary.
struct GradedCount: Equatable, Identifiable {
    /// The check's position in its drill's `checks` array. Drill ViewModels rely on this to index
    /// parallel arrays (e.g. `TrueCountDrillViewModel.askedQuestions`) with a check's `id`.
    let id: Int
    let kind: CountKind
    let expected: Double
    let answered: Double
    let isCorrect: Bool
    let responseMs: Int
    let cardsSeen: Int
    let checkedAt: Date

    var draft: CountCheckDraft {
        CountCheckDraft(kind: kind, expected: expected, answered: answered, isCorrect: isCorrect,
                        responseMs: responseMs, cardsSeen: cardsSeen, checkedAt: checkedAt)
    }

    static func milliseconds(from start: Date, to end: Date) -> Int {
        max(0, Int((end.timeIntervalSince(start) * 1000).rounded()))
    }
}

struct CountSummaryRow: Equatable, Identifiable {
    let id: Int
    let label: String
    let value: String
}

/// What `CountSummaryView` shows for either drill.
struct CountSummaryModel: Equatable {
    let title: String
    let rowsTitle: String
    let score: CountDrillScore
    /// RC only.
    let secondsPerCard: Double?
    let rows: [CountSummaryRow]
}
