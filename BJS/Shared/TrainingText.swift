import BJSCore

/// Display strings shared by the training features and Progress (Step 6 spec §5), so no feature
/// folder imports another's text.
enum TrainingText {
    static let minus = "\u{2212}"

    static func actionName(_ action: Action) -> String {
        switch action {
        case .hit: return "Hit"
        case .stand: return "Stand"
        case .double: return "Double"
        case .split: return "Split"
        case .surrender: return "Surrender"
        }
    }

    static func upcardName(_ rank: Rank) -> String {
        rank == .ace ? "A" : "\(rank.blackjackValue)"
    }

    /// "Hard 16 vs 10", "Soft 18 vs A", "Pair of 8s vs 6", "Pair of Aces vs 2".
    static func handLabel(_ c: WhyContext) -> String {
        let up = upcardName(c.dealerUpCard)
        switch c.handType {
        case .hard: return "Hard \(c.handTotal) vs \(up)"
        case .soft: return "Soft \(c.handTotal) vs \(up)"
        case .pair:
            let rank = c.pairRank ?? .two
            let name = rank == .ace ? "Aces" : "\(rank.blackjackValue)s"
            return "Pair of \(name) vs \(up)"
        }
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

    static func meanError(_ value: Double?) -> String {
        value.map { String(format: "%.1f", $0) } ?? PercentText.noData
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
}
