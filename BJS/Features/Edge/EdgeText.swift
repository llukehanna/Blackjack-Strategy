import Foundation
import BJSCore

/// Edge copy and number formatting. Deterministic (no locale) so it is unit-tested exactly.
enum EdgeText {
    static let minus = "\u{2212}"

    static let breakdownTitle = "Breakdown"
    static let baselineLabel = "Baseline · 8D S17 DAS 3:2"
    static let totalLabel = "House edge"
    static let applyTitle = "Use these rules for training"
    static let appliedCaption = "These are your training rules."
    static let confirmTitle = "Use these rules for training?"
    static let confirmButton = "Use these rules"
    static let toast = "Training rules updated"
    static let footnote = "House edge for basic strategy dealt with a cut card, from WizardOfOdds.com. "
        + "Early surrender uses an 8-deck estimate."

    static func headline(isPlayerEdge: Bool) -> String {
        isPlayerEdge ? "Player edge" : "House edge"
    }

    /// The pinned number: the absolute edge, "0.64%". The headline label carries the sign.
    static func headlineNumber(_ edge: Double) -> String {
        twoDecimals(abs(hundredths(edge))) + "%"
    }

    /// A signed edge for the breakdown: "0.45%", "−0.03%".
    static func edge(_ edge: Double) -> String {
        let h = hundredths(edge)
        return (h < 0 ? minus : "") + twoDecimals(abs(h)) + "%"
    }

    /// A change in house edge: "+0.22%", "−0.19%", "0.00%".
    static func signedChange(_ change: Double) -> String {
        let h = hundredths(change)
        return (h > 0 ? "+" : h < 0 ? minus : "") + twoDecimals(abs(h)) + "%"
    }

    static func comparison(_ delta: Double) -> String {
        "\(signedChange(delta)) vs your training rules"
    }

    static func label(for factor: EdgeFactor) -> String {
        switch factor {
        case .decks(let count): return count.label
        case .dealerHitsSoft17: return "Dealer hits soft 17"
        case .payout(let payout): return "Blackjack pays \(payout.label)"
        case .noDoubleAfterSplit: return "No double after split"
        case .doubleRestriction(let restriction): return "Double on \(restriction.label)"
        case .maxSplitHands(let hands): return "Split to \(hands) hands"
        case .resplitAces: return "Resplit aces"
        case .hitSplitAces: return "Hit split aces"
        case .noHoleCard: return "No hole card"
        case .surrender(let rule, let pricedAsEarly):
            switch rule {
            case .none: return "No surrender"
            case .late: return pricedAsEarly ? "Late surrender (settles as early)" : "Late surrender"
            case .early: return "Early surrender"
            }
        }
    }

    static func accessibility(for factor: EdgeFactor, change: Double) -> String {
        let h = hundredths(change)
        let effect = h == 0
            ? "doesn't change the house edge"
            : "\(h > 0 ? "raises" : "lowers") the house edge by \(twoDecimals(abs(h))) percent"
        return "\(label(for: factor)), \(effect)"
    }

    static func confirmMessage(summary: String) -> String {
        "New drills will use \(summary). Saved sessions keep their own rules."
    }

    private static func hundredths(_ value: Double) -> Int {
        Int((value * 100).rounded())
    }

    /// 64 → "0.64", 170 → "1.70", 5 → "0.05". Expects a non-negative value.
    private static func twoDecimals(_ hundredths: Int) -> String {
        let fraction = hundredths % 100
        return "\(hundredths / 100).\(fraction < 10 ? "0" : "")\(fraction)"
    }
}
