import BJSCore

/// The compact rules line in the hub header, e.g. "6D · H17 · DAS · 3:2".
enum RulesSummary {
    static func text(for rules: BlackjackRules) -> String {
        var parts = ["\(rules.deckCount.rawValue)D",
                     rules.dealerSoft17 == .hits ? "H17" : "S17"]
        if rules.doubleAfterSplit { parts.append("DAS") }
        switch rules.surrenderRule {
        case .none: break
        case .late: parts.append("LS")
        case .early: parts.append("ES")
        }
        if rules.peekRule == .europeanNoPeek { parts.append("ENHC") }
        parts.append(rules.blackjackPayout.label)
        return parts.joined(separator: " · ")
    }
}
