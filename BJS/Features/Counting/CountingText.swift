import Foundation
import BJSCore

/// Counting copy and number formatting. Deterministic (no locale) so it is unit-tested exactly.
enum CountingText {
    static let minus = "\u{2212}"

    struct Feedback: Equatable {
        let headline: String
        let reason: String
    }

    /// "+3", "−2", "0".
    static func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : value < 0 ? "\(minus)\(-value)" : "0"
    }

    /// Rounded to one decimal, ".0" dropped: "+2.3", "−3", "+0.5", "0".
    static func signed(_ value: Double) -> String {
        let tenths = Int((value * 10).rounded())
        if tenths == 0 { return "0" }
        let m = abs(tenths)
        return (tenths > 0 ? "+" : minus) + (m % 10 == 0 ? "\(m / 10)" : "\(m / 10).\(m % 10)")
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

    static func meanError(_ value: Double?) -> String {
        value.map { String(format: "%.1f", $0) } ?? PercentText.noData
    }

    static func runningFeedback(expected: Int, answered: Int) -> Feedback {
        expected == answered
            ? Feedback(headline: "Correct", reason: "The running count is \(signed(expected)).")
            : Feedback(headline: "Running count is \(signed(expected))", reason: "You said \(signed(answered)).")
    }

    static func trueFeedback(question: TrueCountQuestion, convention: TrueCountConvention,
                             answered: Double, isCorrect: Bool) -> Feedback {
        let working = "RC \(signed(question.runningCount)) ÷ \(decksLeft(question.decksRemaining))"
            + " = \(signed(question.exactTrueCount))."
        if isCorrect { return Feedback(headline: "Correct", reason: working) }
        return Feedback(headline: "True count is \(signed(question.keypadAnswer(for: convention)))",
                        reason: "\(working) You said \(signed(answered)).")
    }

    static func cardValueFeedback(rank: Rank) -> Feedback {
        Feedback(headline: "\(rank.spokenName) is \(signed(rank.hiLoValue))",
                 reason: "2 to 6 are +1, 7 to 9 are 0, and 10 to Ace are \(minus)1.")
    }

    static func conventionRule(_ convention: TrueCountConvention) -> String {
        switch convention {
        case .exact:
            return "Exact: any answer within 0.25 of RC ÷ decks left is correct, so halves are enough."
        case .floor:
            return "Floor: round RC ÷ decks left down to the whole number below (\(minus)2.3 becomes \(minus)3)."
        case .truncate:
            return "Truncate: drop the fraction of RC ÷ decks left, toward zero (\(minus)2.3 becomes \(minus)2)."
        }
    }

    static func runningRow(_ check: GradedCount) -> CountSummaryRow {
        let expected = signed(Int(check.expected))
        let value = check.isCorrect ? expected : "\(expected) · you said \(signed(Int(check.answered)))"
        return CountSummaryRow(id: check.id, label: "After card \(check.cardsSeen)", value: value)
    }

    static func trueRow(_ check: GradedCount, question: TrueCountQuestion,
                        convention: TrueCountConvention) -> CountSummaryRow {
        let answer = signed(question.keypadAnswer(for: convention))
        let value = check.isCorrect ? signed(check.answered) : "\(answer) · you said \(signed(check.answered))"
        return CountSummaryRow(id: check.id,
                               label: "\(signed(question.runningCount)) · \(decksLeft(question.decksRemaining))",
                               value: value)
    }
}
