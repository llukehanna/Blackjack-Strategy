import Foundation
import BJSCore

/// Counting copy and number formatting. Deterministic (no locale) so it is unit-tested exactly.
enum CountingText {
    struct Feedback: Equatable {
        let headline: String
        let reason: String
    }

    /// Decks to the quarter: "0.25", "2.5", "3".
    static func decks(_ value: Double) -> String {
        let hundredths = Int((value * 100).rounded())
        let whole = hundredths / 100
        let fraction = hundredths % 100
        if fraction == 0 { return "\(whole)" }
        return fraction % 10 == 0 ? "\(whole).\(fraction / 10)" : "\(whole).\(String(format: "%02d", fraction))"
    }

    static func decksLeft(_ value: Double) -> String {
        value == 1 ? "1 deck left" : "\(decks(value)) decks left"
    }

    static func pace(_ seconds: Double) -> String { String(format: "%.1f s", seconds) }

    static func seconds(_ value: Double) -> String { String(format: "%.2f s", value) }

    static func runningFeedback(expected: Int, answered: Int) -> Feedback {
        expected == answered
            ? Feedback(headline: "Correct", reason: "The running count is \(TrainingText.signed(expected)).")
            : Feedback(headline: "Running count is \(TrainingText.signed(expected))", reason: "You said \(TrainingText.signed(answered)).")
    }

    static func trueFeedback(question: TrueCountQuestion, convention: TrueCountConvention,
                             answered: Double, isCorrect: Bool) -> Feedback {
        let working = "RC \(TrainingText.signed(question.runningCount)) ÷ \(decksLeft(question.decksRemaining))"
            + " = \(TrainingText.signed(question.exactTrueCount))."
        if isCorrect { return Feedback(headline: "Correct", reason: working) }
        return Feedback(headline: "True count is \(TrainingText.signed(question.keypadAnswer(for: convention)))",
                        reason: "\(working) You said \(TrainingText.signed(answered)).")
    }

    static func cardValueFeedback(rank: Rank) -> Feedback {
        Feedback(headline: "\(rank.spokenName) is \(TrainingText.signed(rank.hiLoValue))",
                 reason: "2 to 6 are +1, 7 to 9 are 0, and 10 to Ace are \(TrainingText.minus)1.")
    }

    static func runningRow(_ check: GradedCount) -> CountSummaryRow {
        let expected = TrainingText.signed(Int(check.expected))
        let value = check.isCorrect ? expected : "\(expected) · you said \(TrainingText.signed(Int(check.answered)))"
        return CountSummaryRow(id: check.id, label: "After card \(check.cardsSeen)", value: value)
    }

    static func trueRow(_ check: GradedCount, question: TrueCountQuestion,
                        convention: TrueCountConvention) -> CountSummaryRow {
        let answer = TrainingText.signed(question.keypadAnswer(for: convention))
        let value = check.isCorrect ? TrainingText.signed(check.answered) : "\(answer) · you said \(TrainingText.signed(check.answered))"
        return CountSummaryRow(id: check.id,
                               label: "\(TrainingText.signed(question.runningCount)) · \(decksLeft(question.decksRemaining))",
                               value: value)
    }
}
