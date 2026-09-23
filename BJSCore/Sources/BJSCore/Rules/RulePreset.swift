/// Common casino rule sets used to pre-fill the rules form.
///
/// Presets are a UX convenience only: the app stores a plain `BlackjackRules`
/// value, and `matching(_:)` tells the UI which preset (if any) is active.
public enum RulePreset: String, CaseIterable, Sendable, Identifiable {
    case vegasStrip
    case downtownVegas
    case atlanticCity
    case singleDeckSixFive
    case europeanNoHoleCard

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vegasStrip: return "Vegas Strip"
        case .downtownVegas: return "Downtown Vegas"
        case .atlanticCity: return "Atlantic City"
        case .singleDeckSixFive: return "Single Deck 6:5"
        case .europeanNoHoleCard: return "European (No Hole Card)"
        }
    }

    public var rules: BlackjackRules {
        var r = BlackjackRules()
        switch self {
        case .vegasStrip:
            r.deckCount = .six
            r.dealerSoft17 = .stands
            r.doubleAfterSplit = true
            r.surrenderRule = .none
        case .downtownVegas:
            r.deckCount = .two
            r.dealerSoft17 = .hits
            r.doubleAfterSplit = true
            r.surrenderRule = .late
        case .atlanticCity:
            r.deckCount = .eight
            r.dealerSoft17 = .stands
            r.doubleAfterSplit = true
            r.surrenderRule = .late
        case .singleDeckSixFive:
            r.deckCount = .one
            r.dealerSoft17 = .hits
            r.blackjackPayout = .sixToFive
            r.doubleAfterSplit = false
        case .europeanNoHoleCard:
            r.deckCount = .six
            r.dealerSoft17 = .stands
            r.doubleAfterSplit = true
            r.peekRule = .europeanNoPeek
        }
        return r
    }

    /// The preset whose rules exactly equal `rules`, or nil for a custom rule set.
    public static func matching(_ rules: BlackjackRules) -> RulePreset? {
        allCases.first { $0.rules == rules }
    }
}
