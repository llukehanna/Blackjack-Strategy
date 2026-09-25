import Testing
import BJSCore
@testable import BJS

@MainActor
struct RuleLabelsTests {

    @Test("Hub summary for every preset")
    func presetSummaries() {
        #expect(RulesSummary.text(for: RulePreset.vegasStrip.rules) == "6D · S17 · DAS · 3:2")
        #expect(RulesSummary.text(for: RulePreset.downtownVegas.rules) == "2D · H17 · DAS · LS · 3:2")
        #expect(RulesSummary.text(for: RulePreset.atlanticCity.rules) == "8D · S17 · DAS · LS · 3:2")
        #expect(RulesSummary.text(for: RulePreset.singleDeckSixFive.rules) == "1D · H17 · 6:5")
        #expect(RulesSummary.text(for: RulePreset.europeanNoHoleCard.rules) == "6D · S17 · DAS · ENHC · 3:2")
    }

    @Test("Summary shows early surrender and 2:1")
    func edgeCases() {
        var r = BlackjackRules()
        r.surrenderRule = .early
        r.blackjackPayout = .twoToOne
        r.deckCount = .four
        #expect(RulesSummary.text(for: r) == "4D · S17 · DAS · ES · 2:1")
    }

    @Test("Every rule option has a distinct, non-empty label")
    func labelsCoverEveryCase() {
        func check(_ labels: [String]) {
            #expect(labels.allSatisfy { !$0.isEmpty })
            #expect(Set(labels).count == labels.count)
        }
        check(BlackjackRules.DeckCount.allCases.map { $0.label })
        check(BlackjackRules.DealerSoft17.allCases.map { $0.label })
        check(BlackjackRules.BlackjackPayout.allCases.map { $0.label })
        check(BlackjackRules.SurrenderRule.allCases.map { $0.label })
        check(BlackjackRules.DoubleRestriction.allCases.map { $0.label })
        check(BlackjackRules.PeekRule.allCases.map { $0.label })
        check(TrueCountConvention.allCases.map { $0.label })
    }

    @Test("Specific labels")
    func specificLabels() {
        #expect(BlackjackRules.DeckCount.one.label == "1 deck")
        #expect(BlackjackRules.DeckCount.six.label == "6 decks")
        #expect(BlackjackRules.BlackjackPayout.sixToFive.label == "6:5")
        #expect(BlackjackRules.PeekRule.europeanNoPeek.label == "No hole card")
        #expect(BlackjackRules.DoubleRestriction.nineToEleven.label == "9–11 only")
        #expect(TrueCountConvention.exact.label == "Exact")
    }

    @Test("Preset label is the preset name, or Custom")
    func presetLabel() {
        #expect(RulePreset.label(for: RulePreset.atlanticCity.rules) == "Atlantic City")
        var custom = RulePreset.atlanticCity.rules
        custom.resplitAces = true
        #expect(RulePreset.label(for: custom) == "Custom")
    }
}
