import Testing
@testable import BJSCore

@Suite("RulePreset")
struct RulePresetTests {

    @Test("Vegas Strip is 6D S17 DAS 3:2, no surrender")
    func vegasStrip() {
        let r = RulePreset.vegasStrip.rules
        #expect(r.deckCount == .six)
        #expect(r.dealerSoft17 == .stands)
        #expect(r.doubleAfterSplit)
        #expect(r.blackjackPayout == .threeToTwo)
        #expect(r.surrenderRule == .none)
        #expect(r.peekRule == .americanPeek)
    }

    @Test("Downtown Vegas is 2D H17 DAS late surrender")
    func downtown() {
        let r = RulePreset.downtownVegas.rules
        #expect(r.deckCount == .two)
        #expect(r.dealerSoft17 == .hits)
        #expect(r.surrenderRule == .late)
    }

    @Test("Atlantic City is 8D S17 DAS late surrender")
    func atlanticCity() {
        let r = RulePreset.atlanticCity.rules
        #expect(r.deckCount == .eight)
        #expect(r.dealerSoft17 == .stands)
        #expect(r.surrenderRule == .late)
        #expect(r.doubleAfterSplit)
    }

    @Test("Single deck 6:5 is 1D H17 6:5 no DAS")
    func singleDeck65() {
        let r = RulePreset.singleDeckSixFive.rules
        #expect(r.deckCount == .one)
        #expect(r.dealerSoft17 == .hits)
        #expect(r.blackjackPayout == .sixToFive)
        #expect(!r.doubleAfterSplit)
    }

    @Test("European is 6D S17 DAS with no hole card")
    func european() {
        let r = RulePreset.europeanNoHoleCard.rules
        #expect(r.deckCount == .six)
        #expect(r.peekRule == .europeanNoPeek)
    }

    @Test("Every preset has a distinct rule set and matches itself")
    func matching() {
        let all = RulePreset.allCases.map(\.rules)
        #expect(Set(all).count == RulePreset.allCases.count)
        for preset in RulePreset.allCases {
            #expect(RulePreset.matching(preset.rules) == preset)
        }
    }

    @Test("Custom rules match no preset")
    func customMatchesNothing() {
        var r = BlackjackRules()
        r.maxSplitHands = 2
        r.deckCount = .four
        #expect(RulePreset.matching(r) == nil)
    }

    @Test("Display names are human readable")
    func names() {
        #expect(RulePreset.vegasStrip.displayName == "Vegas Strip")
        #expect(RulePreset.singleDeckSixFive.displayName == "Single Deck 6:5")
    }
}
