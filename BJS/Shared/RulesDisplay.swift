import BJSCore

// Display text for rules and preferences. Presentation only; the values live in BJSCore.

extension BlackjackRules.DeckCount {
    var displayName: String { rawValue == 1 ? "1 deck" : "\(rawValue) decks" }
    var shortName: String { "\(rawValue)D" }
}

extension BlackjackRules.DealerSoft17 {
    var displayName: String {
        switch self {
        case .stands: return "Stands"
        case .hits: return "Hits"
        }
    }

    var shortName: String {
        switch self {
        case .stands: return "S17"
        case .hits: return "H17"
        }
    }
}

extension BlackjackRules.BlackjackPayout {
    var displayName: String {
        switch self {
        case .threeToTwo: return "3:2"
        case .sixToFive: return "6:5"
        case .twoToOne: return "2:1"
        }
    }
}

extension BlackjackRules.SurrenderRule {
    var displayName: String {
        switch self {
        case .none: return "None"
        case .late: return "Late"
        case .early: return "Early"
        }
    }

    /// nil when there is no surrender.
    var shortName: String? {
        switch self {
        case .none: return nil
        case .late: return "LS"
        case .early: return "ES"
        }
    }
}

extension BlackjackRules.DoubleRestriction {
    var displayName: String {
        switch self {
        case .anyTwo: return "Any two cards"
        case .nineToEleven: return "9–11 only"
        case .tenToEleven: return "10–11 only"
        }
    }
}

extension BlackjackRules.PeekRule {
    var displayName: String {
        switch self {
        case .americanPeek: return "Peeks (US)"
        case .europeanNoPeek: return "No hole card"
        }
    }
}

extension TrueCountConvention {
    var displayName: String {
        switch self {
        case .exact: return "Exact"
        case .floor: return "Floor"
        case .truncate: return "Truncate"
        }
    }
}

enum RulesSummary {
    /// Compact rules line for the hub header, e.g. "6D · H17 · DAS · 3:2".
    /// Surrender ("LS"/"ES") and no-hole-card ("ENHC") are appended only when they apply.
    static func short(_ rules: BlackjackRules) -> String {
        var parts = [
            rules.deckCount.shortName,
            rules.dealerSoft17.shortName,
            rules.doubleAfterSplit ? "DAS" : "NDAS",
            rules.blackjackPayout.displayName,
        ]
        if let surrender = rules.surrenderRule.shortName { parts.append(surrender) }
        if rules.peekRule == .europeanNoPeek { parts.append("ENHC") }
        return parts.joined(separator: " · ")
    }

    /// Preset name, or "Custom" when the rules match no preset.
    static func presetName(_ preset: RulePreset?) -> String {
        preset?.displayName ?? "Custom"
    }
}
