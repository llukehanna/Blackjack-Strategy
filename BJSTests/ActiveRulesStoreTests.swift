import BJSCore
import Foundation
import Testing
@testable import BJS

@MainActor
@Suite("ActiveRulesStore")
struct ActiveRulesStoreTests {

    @Test("A fresh install uses the default rules (which match Vegas Strip)")
    func defaults() {
        let store = ActiveRulesStore(defaults: TestDefaults.make())
        #expect(store.rules == BlackjackRules())
        #expect(store.matchingPreset == .vegasStrip)
    }

    @Test("Changes persist across store instances")
    func persists() {
        let defaults = TestDefaults.make()
        let store = ActiveRulesStore(defaults: defaults)
        store.rules.deckCount = .two
        store.rules.surrenderRule = .late

        let reloaded = ActiveRulesStore(defaults: defaults)
        #expect(reloaded.rules.deckCount == .two)
        #expect(reloaded.rules.surrenderRule == .late)
    }

    @Test("Stored value is JSON Data under 'activeRules' (readable by @AppStorage Data)")
    func storageFormat() throws {
        let defaults = TestDefaults.make()
        let store = ActiveRulesStore(defaults: defaults)
        store.apply(.atlanticCity)
        let data = try #require(defaults.data(forKey: "activeRules"))
        #expect(try RulesCoding.decode(data) == RulePreset.atlanticCity.rules)
    }

    @Test("Corrupt JSON falls back to default rules")
    func corruptFallsBack() {
        let defaults = TestDefaults.make()
        defaults.set(Data("not json".utf8), forKey: "activeRules")
        #expect(ActiveRulesStore(defaults: defaults).rules == BlackjackRules())
    }

    @Test("Applying a preset sets its rules; custom rules match no preset")
    func presets() {
        let store = ActiveRulesStore(defaults: TestDefaults.make())
        store.apply(.singleDeckSixFive)
        #expect(store.matchingPreset == .singleDeckSixFive)
        store.rules.maxSplitHands = 2
        #expect(store.matchingPreset == nil)
    }
}

@Suite("Rules display")
struct RulesDisplayTests {

    @Test("Hub summary", arguments: [
        (BlackjackRules(), "6D · S17 · DAS · 3:2"),
        (RulePreset.downtownVegas.rules, "2D · H17 · DAS · 3:2 · LS"),
        (RulePreset.singleDeckSixFive.rules, "1D · H17 · NDAS · 6:5"),
        (RulePreset.europeanNoHoleCard.rules, "6D · S17 · DAS · 3:2 · ENHC"),
    ])
    func summary(_ rules: BlackjackRules, _ expected: String) {
        #expect(RulesSummary.short(rules) == expected)
    }

    @Test("Custom rules are named Custom")
    func presetName() {
        #expect(RulesSummary.presetName(nil) == "Custom")
        #expect(RulesSummary.presetName(.vegasStrip) == "Vegas Strip")
    }

    @Test("Rules JSON round-trips")
    func roundTrip() throws {
        for preset in RulePreset.allCases {
            #expect(try RulesCoding.decode(RulesCoding.encode(preset.rules)) == preset.rules)
        }
    }
}
