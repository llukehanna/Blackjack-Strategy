import Testing
@testable import BJS
import BJSCore

struct CasinoPresetTests {
    @Test func vegasStripPresetHasCorrectRules() {
        let rules = CasinoPreset.vegasStrip.rules
        #expect(rules.deckCount == .six)
        #expect(rules.dealerSoft17 == .stands)
        #expect(rules.blackjackPayout == .threeToTwo)
        #expect(rules.doubleAfterSplit == true)
        #expect(rules.surrenderRule == .none)
        #expect(rules.doubleRestriction == .anyTwo)
        #expect(rules.peekRule == .americanPeek)
    }

    @Test func downtownVegasPresetHasCorrectRules() {
        let rules = CasinoPreset.downtownVegas.rules
        #expect(rules.deckCount == .two)
        #expect(rules.dealerSoft17 == .hits)
        #expect(rules.blackjackPayout == .threeToTwo)
        #expect(rules.doubleAfterSplit == true)
        #expect(rules.surrenderRule == .late)
        #expect(rules.doubleRestriction == .anyTwo)
        #expect(rules.peekRule == .americanPeek)
    }

    @Test func customPresetReturnsDefaultRules() {
        let rules = CasinoPreset.custom.rules
        let defaults = BlackjackRules()
        #expect(rules == defaults)
    }

    @Test func allPresetsHaveUniqueRawValues() {
        let rawValues = CasinoPreset.allCases.map(\.rawValue)
        #expect(Set(rawValues).count == rawValues.count)
    }

    @Test func vegasStripAndCustomAreEquivalent() {
        // Custom starts from default = same as Vegas Strip
        #expect(CasinoPreset.vegasStrip.rules == CasinoPreset.custom.rules)
    }

    @Test func onlyCustomIsEditable() {
        #expect(CasinoPreset.vegasStrip.isEditable == false)
        #expect(CasinoPreset.downtownVegas.isEditable == false)
        #expect(CasinoPreset.custom.isEditable == true)
    }
}
