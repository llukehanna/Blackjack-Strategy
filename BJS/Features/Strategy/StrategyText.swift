import BJSCore
import Foundation

/// Short display strings for the trainer and the summary. Presentation only.
enum StrategyText {
    /// "Hand 3 of 25", or "Hand 3" in Endless.
    static func progress(handNumber: Int, limit: Int?) -> String {
        limit.map { "Hand \(handNumber) of \($0)" } ?? "Hand \(handNumber)"
    }

    /// Hand total label: "16", soft hands as "8/18", "21", "Bust".
    static func total(_ hand: BlackjackHand) -> String {
        if hand.isBust { return "Bust" }
        if hand.isSoft && hand.total < 21 { return "\(hand.total - 10)/\(hand.total)" }
        return "\(hand.total)"
    }

    /// The dealer's result once revealed: "Dealer has 19", "Dealer busts".
    static func dealerResult(_ dealer: BlackjackHand) -> String {
        dealer.isBust ? "Dealer busts" : "Dealer has \(dealer.total)"
    }

    /// Net result in bets: "+1", "−2", "0", "+1.5", "−0.5" (true minus sign).
    static func net(_ units: Double) -> String {
        if units == 0 { return "0" }
        let magnitude = abs(units)
        let number = magnitude == magnitude.rounded() ? String(Int(magnitude)) : String(magnitude)
        return (units > 0 ? "+" : "\u{2212}") + number
    }

    /// One player hand's result: "Win +1", "Bust −2", "Push 0", "Surrendered −0.5".
    static func outcome(_ state: PlayerHandState) -> String {
        let name: String
        switch state.outcome {
        case .blackjack: name = "Blackjack"
        case .win: name = "Win"
        case .push: name = "Push"
        case .loss: name = "Loss"
        case .bust: name = "Bust"
        case .surrendered: name = "Surrendered"
        case nil: return ""
        }
        return "\(name) \(net(state.net))"
    }

    /// "87%", or "—" with no decisions.
    static func percent(_ accuracy: Double?) -> String {
        guard let accuracy else { return "—" }
        return "\(Int((accuracy * 100).rounded()))%"
    }

    /// Mean decision time: "1.4 s", or "—".
    static func seconds(fromMs ms: Double?) -> String {
        guard let ms else { return "—" }
        return String(format: "%.1f s", ms / 1_000)
    }

    /// A mistakes-list row's detail: "You: Stand · Play: Hit".
    static func mistakeDetail(_ decision: GradedDecision) -> String {
        "You: \(DecisionFeedback.choiceName(decision.choice)) · Play: \(DecisionFeedback.actionName(decision.correctAction))"
    }
}
