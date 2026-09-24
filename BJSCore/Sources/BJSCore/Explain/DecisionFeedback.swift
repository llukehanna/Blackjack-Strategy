/// The FeedbackCard's headline and one-line reason, and the short names the trainer,
/// the WHY sheet and the summary's mistakes list use for a decision.
///
/// Examples (hard 16 vs 7, basic strategy hits):
/// - correct:   "Correct: Hit" / "Basic strategy hits hard 16 against a 7."
/// - incorrect: "The play is Hit" / "You chose Stand. Basic strategy hits hard 16 against a 7."
/// - timeout:   "Time's up: Hit" / "No action in time. Basic strategy hits hard 16 against a 7."
public enum DecisionFeedback {

    /// "Hit", "Stand", "Double", "Split", "Surrender".
    public static func actionName(_ action: Action) -> String {
        action.rawValue.capitalized
    }

    /// "Stand", or "Timeout".
    public static func choiceName(_ choice: DecisionChoice) -> String {
        choice.action.map(actionName) ?? "Timeout"
    }

    /// Dealer upcard in `TrainingCell` form (2...11): "2" … "10", "Ace".
    public static func upcardName(_ value: Int) -> String {
        value == 11 ? "Ace" : String(value)
    }

    /// Pair rank in `TrainingCell` form (2...11): "2s" … "10s", "Aces".
    public static func pairName(_ value: Int) -> String {
        value == 11 ? "Aces" : "\(value)s"
    }

    /// "Hard 16", "Soft 18", "Pair of 8s", "Pair of Aces".
    public static func handName(_ cell: TrainingCell) -> String {
        switch cell.handType {
        case .hard: return "Hard \(cell.playerValue)"
        case .soft: return "Soft \(cell.playerValue)"
        case .pair: return "Pair of \(pairName(cell.playerValue))"
        }
    }

    /// "Hard 16 vs 7", "Pair of Aces vs Ace".
    public static func spotTitle(_ cell: TrainingCell) -> String {
        "\(handName(cell)) vs \(upcardName(cell.dealerUpcard))"
    }

    /// The WHY sheet's title, from its context: "Hard 16 vs 7".
    public static func spotTitle(_ context: WhyContext) -> String {
        let upcard = context.dealerUpCard == .ace ? 11 : context.dealerUpCard.blackjackValue
        let value: Int
        if context.handType == .pair, let rank = context.pairRank {
            value = rank == .ace ? 11 : rank.blackjackValue
        } else {
            value = context.handTotal
        }
        return spotTitle(TrainingCell(handType: context.handType, playerValue: value, dealerUpcard: upcard))
    }

    public static func headline(for decision: GradedDecision) -> String {
        let correct = actionName(decision.correctAction)
        switch decision.choice {
        case .timeout: return "Time's up: \(correct)"
        case .action: return decision.isCorrect ? "Correct: \(correct)" : "The play is \(correct)"
        }
    }

    public static func reason(for decision: GradedDecision) -> String {
        let rule = "Basic strategy \(verb(decision.correctAction)) \(handPhrase(decision.cell)) against \(article(decision.cell.dealerUpcard)) \(upcardName(decision.cell.dealerUpcard))."
        switch decision.choice {
        case .timeout: return "No action in time. \(rule)"
        case .action(let chosen):
            return decision.isCorrect ? rule : "You chose \(actionName(chosen)). \(rule)"
        }
    }

    // MARK: - Helpers

    /// "hits", "stands on", "doubles", "splits", "surrenders".
    private static func verb(_ action: Action) -> String {
        switch action {
        case .hit: return "hits"
        case .stand: return "stands on"
        case .double: return "doubles"
        case .split: return "splits"
        case .surrender: return "surrenders"
        }
    }

    /// "hard 16", "soft 18", "a pair of 8s".
    private static func handPhrase(_ cell: TrainingCell) -> String {
        switch cell.handType {
        case .hard: return "hard \(cell.playerValue)"
        case .soft: return "soft \(cell.playerValue)"
        case .pair: return "a pair of \(pairName(cell.playerValue))"
        }
    }

    /// "an" before 8 and Ace, "a" otherwise.
    private static func article(_ upcard: Int) -> String {
        upcard == 8 || upcard == 11 ? "an" : "a"
    }
}
