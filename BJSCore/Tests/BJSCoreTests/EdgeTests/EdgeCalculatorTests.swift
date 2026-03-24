import Testing
@testable import BJSCore

struct EdgeTestCase: Sendable {
    let label: String
    let rules: BlackjackRules
    let expectedEdge: Double
    let tolerance: Double = 0.02
}

extension EdgeTestCase: CustomTestStringConvertible {
    var testDescription: String { label }
}

let edgeTestCases: [EdgeTestCase] = [
    // Case 1: 6D S17 DAS standard
    EdgeTestCase(label: "6D S17 DAS standard", rules: {
        let r = BlackjackRules()
        // defaults: 6D S17 DAS no-surr 3:2 4-splits peek any-two
        return r
    }(), expectedEdge: 0.40),

    // Case 2: 6D H17 DAS
    EdgeTestCase(label: "6D H17 DAS", rules: {
        var r = BlackjackRules()
        r.dealerSoft17 = .hits
        return r
    }(), expectedEdge: 0.62),

    // Case 3: 6D S17 DAS late surrender
    EdgeTestCase(label: "6D S17 DAS late surrender", rules: {
        var r = BlackjackRules()
        r.surrenderRule = .late
        return r
    }(), expectedEdge: 0.33),

    // Case 4: 8D S17 DAS (baseline)
    EdgeTestCase(label: "8D S17 DAS baseline", rules: {
        var r = BlackjackRules()
        r.deckCount = .eight
        return r
    }(), expectedEdge: 0.43),

    // Case 5: 1D H17 DAS
    EdgeTestCase(label: "1D H17 DAS", rules: {
        var r = BlackjackRules()
        r.deckCount = .one
        r.dealerSoft17 = .hits
        return r
    }(), expectedEdge: 0.04),

    // Case 6: 1D H17 NDAS D9-11 max-2-splits
    EdgeTestCase(label: "1D H17 NDAS D9-11 2-splits", rules: {
        var r = BlackjackRules()
        r.deckCount = .one
        r.dealerSoft17 = .hits
        r.doubleAfterSplit = false
        r.doubleRestriction = .nineToEleven
        r.maxSplitHands = 2
        return r
    }(), expectedEdge: 0.05),

    // Case 7: 1D H17 DAS 6:5
    EdgeTestCase(label: "1D H17 DAS 6:5", rules: {
        var r = BlackjackRules()
        r.deckCount = .one
        r.dealerSoft17 = .hits
        r.blackjackPayout = .sixToFive
        return r
    }(), expectedEdge: 1.44),

    // Case 8: 2D H17 DAS
    EdgeTestCase(label: "2D H17 DAS", rules: {
        var r = BlackjackRules()
        r.deckCount = .two
        r.dealerSoft17 = .hits
        return r
    }(), expectedEdge: 0.19),

    // Case 9: 6D S17 DAS late-surr RSA
    EdgeTestCase(label: "6D S17 DAS late-surr RSA", rules: {
        var r = BlackjackRules()
        r.surrenderRule = .late
        r.resplitAces = true
        return r
    }(), expectedEdge: 0.26),

    // Case 10: 8D H17 DAS late surrender
    // Note: Plan specified 0.35% but delta computation gives 0.43 + 0.22 - 0.08 = 0.57%.
    // The plan's "computed" note confirms: baseline 0.43 + H17(+0.22 house edge) - LS(-0.08 house edge).
    // 0.57% is the correct delta-computed value.
    EdgeTestCase(label: "8D H17 DAS late surrender", rules: {
        var r = BlackjackRules()
        r.deckCount = .eight
        r.dealerSoft17 = .hits
        r.surrenderRule = .late
        return r
    }(), expectedEdge: 0.57),

    // Case 11: 4D S17 NDAS D9-11 max-3-splits
    EdgeTestCase(label: "4D S17 NDAS D9-11 3-splits", rules: {
        var r = BlackjackRules()
        r.deckCount = .four
        r.doubleAfterSplit = false
        r.doubleRestriction = .nineToEleven
        r.maxSplitHands = 3
        return r
    }(), expectedEdge: 0.51),

    // Case 12: 6D S17 DAS 6:5
    EdgeTestCase(label: "6D S17 DAS 6:5", rules: {
        var r = BlackjackRules()
        r.blackjackPayout = .sixToFive
        return r
    }(), expectedEdge: 1.79),
]

@Suite("Edge Calculator")
struct EdgeCalculatorTests {

    @Test("Edge calculator matches WoO reference", arguments: edgeTestCases)
    func edgeMatchesWizardOfOdds(testCase: EdgeTestCase) {
        let calculator = EdgeCalculator()
        let result = calculator.analyze(rules: testCase.rules)
        #expect(abs(result.houseEdge - testCase.expectedEdge) <= testCase.tolerance,
                "\(testCase.label): Expected \(testCase.expectedEdge)% but got \(result.houseEdge)%")
    }

    @Test("Edge contributions sum to total edge")
    func contributionsSumToTotal() {
        let calculator = EdgeCalculator()
        var rules = BlackjackRules()
        rules.dealerSoft17 = .hits
        rules.surrenderRule = .late
        let result = calculator.analyze(rules: rules)
        let summedEdge = EdgeCalculator.baselineHouseEdge - result.contributions.reduce(0.0) { $0 + $1.delta }
        #expect(abs(summedEdge - result.houseEdge) < 0.001,
                "Contributions should sum to total edge")
    }

    @Test("H17 contribution is approximately -0.22%")
    func h17Contribution() {
        let calculator = EdgeCalculator()
        var rules = BlackjackRules()
        rules.dealerSoft17 = .hits
        let result = calculator.analyze(rules: rules)
        let h17 = result.contributions.first { $0.rule.contains("soft 17") }
        #expect(h17 != nil, "Should have H17 contribution")
        #expect(abs(h17!.delta - (-0.22)) < 0.001, "H17 delta should be -0.22%")
    }

    @Test("6:5 contribution is approximately -1.39%")
    func sixToFiveContribution() {
        let calculator = EdgeCalculator()
        var rules = BlackjackRules()
        rules.blackjackPayout = .sixToFive
        let result = calculator.analyze(rules: rules)
        let sixFive = result.contributions.first { $0.rule.contains("6:5") }
        #expect(sixFive != nil, "Should have 6:5 contribution")
        #expect(abs(sixFive!.delta - (-1.39)) < 0.001, "6:5 delta should be -1.39%")
    }

    @Test("Baseline rules (8D S17 DAS) produce 0.43% edge with no contributions")
    func baselineRulesNoContributions() {
        let calculator = EdgeCalculator()
        var rules = BlackjackRules()
        rules.deckCount = .eight
        let result = calculator.analyze(rules: rules)
        #expect(result.contributions.isEmpty,
                "Baseline rules should produce no rule contributions")
        #expect(abs(result.houseEdge - 0.43) < 0.001)
    }

    @Test("houseEdge(for:) convenience method matches analyze result")
    func convenienceMethodMatches() {
        let calculator = EdgeCalculator()
        var rules = BlackjackRules()
        rules.dealerSoft17 = .hits
        rules.surrenderRule = .late
        let analyzeResult = calculator.analyze(rules: rules)
        let convenienceResult = calculator.houseEdge(for: rules)
        #expect(analyzeResult.houseEdge == convenienceResult)
    }
}
