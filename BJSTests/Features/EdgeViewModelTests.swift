import Testing
import BJSCore
@testable import BJS

@MainActor
struct EdgeViewModelTests {

    @Test("Starts from the active rules with nothing to apply")
    func startsFromActiveRules() {
        let model = EdgeViewModel(activeRules: RulePreset.downtownVegas.rules)
        #expect(model.rules == RulePreset.downtownVegas.rules)
        #expect(abs(model.result.houseEdge - 0.39072) < 0.00001)
        #expect(model.rating == .good)
        #expect(!model.isPlayerEdge)
        #expect(model.comparison == nil)
        #expect(!model.canApply)
    }

    @Test("Editing a rule updates the result and the comparison")
    func comparisonFollowsEdits() throws {
        let model = EdgeViewModel(activeRules: BlackjackRules())
        model.rules.dealerSoft17 = .hits
        #expect(abs(model.result.houseEdge - 0.63873) < 0.00001)
        #expect(model.rating == .ok)
        #expect(model.canApply)
        let comparison = try #require(model.comparison)
        #expect(abs(comparison - (0.63873 - 0.42622)) < 0.00001)

        model.rules.dealerSoft17 = .stands
        #expect(model.comparison == nil)
        #expect(!model.canApply)
    }

    @Test("A better game gives a negative comparison")
    func negativeComparison() throws {
        let model = EdgeViewModel(activeRules: BlackjackRules())
        model.rules.surrenderRule = .late
        let comparison = try #require(model.comparison)
        #expect(abs(comparison - (0.35361 - 0.42622)) < 0.00001)
    }

    @Test("Apply writes the store and clears the comparison")
    func applyWritesStore() {
        let store = ActiveRulesStore(defaults: makeTestDefaults())
        let model = EdgeViewModel(activeRules: store.rules)
        model.rules = RulePreset.singleDeckSixFive.rules
        model.apply(to: store)
        #expect(store.rules == RulePreset.singleDeckSixFive.rules)
        #expect(model.activeRules == RulePreset.singleDeckSixFive.rules)
        #expect(!model.canApply)
        #expect(model.comparison == nil)
    }

    @Test("A single-deck S17 game is a player edge")
    func playerEdge() {
        var rules = BlackjackRules()
        rules.deckCount = .one
        let model = EdgeViewModel(activeRules: rules)
        #expect(model.isPlayerEdge)
        #expect(model.rating == .good)
    }

    @Test("Breakdown bars scale to the largest change, with a floor")
    func breakdownScale() {
        let model = EdgeViewModel(activeRules: RulePreset.singleDeckSixFive.rules)
        #expect(abs(model.breakdownScale - (1.55422 - 0.15945)) < 1e-9)  // the 6:5 step

        model.rules = EdgeCalculator.baselineRules
        #expect(model.result.contributions.isEmpty)
        #expect(model.breakdownScale == 0.01)
    }

    @Test("A small negative edge that rounds to 0.00% is not shown as a player edge")
    func roundsToZeroIsNotPlayerEdge() {
        // 1D S17 no-DAS, split to 2 hands, hit split aces: WoO -0.00399.
        var rules = BlackjackRules()
        rules.deckCount = .one
        rules.doubleAfterSplit = false
        rules.maxSplitHands = 2
        rules.hitSplitAces = true
        let model = EdgeViewModel(activeRules: rules)
        #expect(abs(model.result.houseEdge - (-0.00399)) < 0.00001)
        #expect(!model.isPlayerEdge)
        #expect(EdgeText.headlineNumber(model.result.houseEdge) == "0.00%")
    }

    @Test("An edge that rounds up to 0.50% is rated OK, not Good")
    func roundsUpToRatingBoundary() {
        // 2D S17, no DAS, double 10-11, split to 4 hands, RSA, peek, late surrender, 3:2: WoO
        // 0.4998, which rounds to the 0.50% Good/OK boundary.
        var rules = BlackjackRules()
        rules.deckCount = .two
        rules.dealerSoft17 = .stands
        rules.doubleAfterSplit = false
        rules.doubleRestriction = .tenToEleven
        rules.maxSplitHands = 4
        rules.resplitAces = true
        rules.peekRule = .americanPeek
        rules.surrenderRule = .late
        let model = EdgeViewModel(activeRules: rules)
        #expect(abs(model.result.houseEdge - 0.4998) < 0.00001)
        #expect(EdgeText.headlineNumber(model.result.houseEdge) == "0.50%")
        #expect(model.rating == .ok)
    }

    @Test("displayedEdge rounds to hundredths for rating and player-edge purposes")
    func displayedEdgeRoundingBoundary() {
        #expect(EdgeRating(houseEdge: EdgeViewModel.displayedEdge(0.4998)) == .ok)
        #expect(EdgeViewModel.displayedEdge(-0.00399) == 0.0)
    }
}
