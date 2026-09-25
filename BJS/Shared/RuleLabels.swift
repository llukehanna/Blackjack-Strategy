import BJSCore

extension BlackjackRules.DeckCount {
    var label: String { rawValue == 1 ? "1 deck" : "\(rawValue) decks" }
}

extension BlackjackRules.DealerSoft17 {
    var label: String {
        switch self {
        case .stands: return "Stands"
        case .hits: return "Hits"
        }
    }
}

extension BlackjackRules.BlackjackPayout {
    var label: String {
        switch self {
        case .threeToTwo: return "3:2"
        case .sixToFive: return "6:5"
        case .twoToOne: return "2:1"
        }
    }
}

extension BlackjackRules.SurrenderRule {
    var label: String {
        switch self {
        case .none: return "None"
        case .late: return "Late"
        case .early: return "Early"
        }
    }
}

extension BlackjackRules.DoubleRestriction {
    var label: String {
        switch self {
        case .anyTwo: return "Any two cards"
        case .nineToEleven: return "9–11 only"
        case .tenToEleven: return "10–11 only"
        }
    }
}

extension BlackjackRules.PeekRule {
    var label: String {
        switch self {
        case .americanPeek: return "Dealer peeks"
        case .europeanNoPeek: return "No hole card"
        }
    }
}

extension TrueCountConvention {
    var label: String {
        switch self {
        case .exact: return "Exact"
        case .floor: return "Floor"
        case .truncate: return "Truncate"
        }
    }
}

extension RulePreset {
    /// The matching preset's name, or "Custom".
    static func label(for rules: BlackjackRules) -> String {
        matching(rules)?.displayName ?? "Custom"
    }
}
