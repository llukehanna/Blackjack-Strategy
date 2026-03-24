import Foundation
import BJSCore

enum CasinoPreset: String, CaseIterable, Identifiable {
    case vegasStrip = "Vegas Strip"
    case downtownVegas = "Downtown Vegas"
    case custom = "Custom"

    var id: String { rawValue }

    /// Returns the BlackjackRules for this preset.
    /// For `.custom`, returns the default rules (same as Vegas Strip) as a starting point.
    var rules: BlackjackRules {
        switch self {
        case .vegasStrip:
            var r = BlackjackRules()
            r.deckCount = .six
            r.dealerSoft17 = .stands
            r.blackjackPayout = .threeToTwo
            r.doubleAfterSplit = true
            r.resplitAces = false
            r.hitSplitAces = false
            r.maxSplitHands = 4
            r.surrenderRule = .none
            r.doubleRestriction = .anyTwo
            r.peekRule = .americanPeek
            return r

        case .downtownVegas:
            var r = BlackjackRules()
            r.deckCount = .two
            r.dealerSoft17 = .hits
            r.blackjackPayout = .threeToTwo
            r.doubleAfterSplit = true
            r.resplitAces = false
            r.hitSplitAces = false
            r.maxSplitHands = 4
            r.surrenderRule = .late
            r.doubleRestriction = .anyTwo
            r.peekRule = .americanPeek
            return r

        case .custom:
            return BlackjackRules()  // Default = Vegas Strip rules
        }
    }

    /// Whether the user can edit rules for this preset
    var isEditable: Bool {
        self == .custom
    }
}
