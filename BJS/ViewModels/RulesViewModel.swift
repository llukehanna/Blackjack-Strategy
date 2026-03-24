import Foundation
import SwiftUI
import BJSCore

@Observable
class RulesViewModel {
    var rules: BlackjackRules
    var selectedPreset: CasinoPreset

    init() {
        // Load persisted rules from UserDefaults, or fall back to Vegas Strip defaults
        if let data = UserDefaults.standard.data(forKey: "activeRules"),
           let savedRules = try? JSONDecoder().decode(BlackjackRules.self, from: data) {
            self.rules = savedRules
            // Determine which preset matches the saved rules
            if savedRules == CasinoPreset.vegasStrip.rules {
                self.selectedPreset = .vegasStrip
            } else if savedRules == CasinoPreset.downtownVegas.rules {
                self.selectedPreset = .downtownVegas
            } else {
                self.selectedPreset = .custom
            }
        } else {
            self.rules = CasinoPreset.vegasStrip.rules
            self.selectedPreset = .vegasStrip
        }
    }

    /// Called when user picks a preset from the picker.
    func selectPreset(_ preset: CasinoPreset) {
        selectedPreset = preset
        if preset != .custom {
            rules = preset.rules
        }
        // When switching to Custom, keep current rules as-is (user edits from here)
        persistRules()
    }

    /// Called when user edits any individual rule field.
    /// Automatically switches preset to .custom if rules no longer match a preset.
    func rulesDidChange() {
        if rules == CasinoPreset.vegasStrip.rules {
            selectedPreset = .vegasStrip
        } else if rules == CasinoPreset.downtownVegas.rules {
            selectedPreset = .downtownVegas
        } else {
            selectedPreset = .custom
        }
        persistRules()
    }

    /// Persists the current rules to UserDefaults so they survive app restarts (per D-11).
    func persistRules() {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: "activeRules")
        }
    }

    /// Human-readable summary of current rules for the session start screen.
    var rulesSummary: String {
        let parts: [String] = [
            "\(rules.deckCount.rawValue)-deck",
            rules.dealerSoft17 == .stands ? "S17" : "H17",
            rules.blackjackPayout == .threeToTwo ? "3:2" :
                rules.blackjackPayout == .sixToFive ? "6:5" : "2:1",
            rules.doubleAfterSplit ? "DAS" : "No DAS",
            rules.surrenderRule == .none ? "No Surr" :
                rules.surrenderRule == .late ? "Late Surr" : "Early Surr",
        ]
        return parts.joined(separator: " \u{00B7} ")
    }
}
