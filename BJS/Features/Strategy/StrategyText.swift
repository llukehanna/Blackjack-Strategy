import BJSCore

/// Display strings for the Strategy trainer.
enum StrategyText {

    static func feedback(isCorrect: Bool, chosen: RecordedChoice, correct: Action,
                         label: String) -> (headline: String, reason: String) {
        let lowered = label.prefix(1).lowercased() + label.dropFirst()
        switch chosen {
        case .timeout:
            return ("Time's up", "The play was \(TrainingText.actionName(correct)) on \(lowered).")
        case .action(let action):
            if isCorrect { return ("Correct: \(TrainingText.actionName(correct))", label) }
            return ("The play is \(TrainingText.actionName(correct))", "You chose \(TrainingText.actionName(action)) on \(lowered).")
        }
    }

    /// "+1", "+1.5", "−2", "−0.5", "±0".
    static func signedUnits(_ value: Double) -> String {
        if value == 0 { return "±0" }
        let magnitude = abs(value)
        let number = magnitude == magnitude.rounded() ? "\(Int(magnitude))" : "\(magnitude)"
        return (value > 0 ? "+" : "−") + number
    }

    /// One line for the dealer, then one per player hand ("Hand 2: Win +1" after splits).
    static func outcomeLines(hands: [PlayerHandState], dealer: BlackjackHand) -> [String] {
        var lines: [String] = []
        if dealer.isBlackjack {
            lines.append("Dealer blackjack")
        } else if dealer.isBust {
            lines.append("Dealer busts with \(dealer.total)")
        } else {
            lines.append("Dealer \(dealer.total)")
        }
        for (index, state) in hands.enumerated() {
            let result: String
            switch state.outcome {
            case .blackjack: result = "Blackjack"
            case .win: result = "Win"
            case .push: result = "Push"
            case .loss: result = "Lose"
            case .bust: result = "Bust"
            case .surrendered: result = "Surrender"
            case nil: result = "—"
            }
            let prefix = hands.count > 1 ? "Hand \(index + 1): " : ""
            lines.append("\(prefix)\(result) \(signedUnits(state.net))")
        }
        return lines
    }
}
