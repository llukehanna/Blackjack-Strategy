import Testing
@testable import BJSCore

@Suite("EdgeRating")
struct EdgeRatingTests {

    @Test("Thresholds including boundaries", arguments: [
        (-0.20, EdgeRating.good), (0.0, .good), (0.49, .good),
        (0.50, .ok), (0.75, .ok), (1.00, .ok),
        (1.01, .poor), (2.0, .poor),
    ])
    func thresholds(edge: Double, expected: EdgeRating) {
        #expect(EdgeRating(houseEdge: edge) == expected)
    }

    @Test("Vegas Strip rates Good; single-deck 6:5 rates Poor")
    func presets() {
        let calc = EdgeCalculator()
        #expect(EdgeRating(houseEdge: calc.houseEdge(for: RulePreset.vegasStrip.rules)) == .good)
        #expect(EdgeRating(houseEdge: calc.houseEdge(for: RulePreset.singleDeckSixFive.rules)) == .poor)
    }

    @Test("Display names")
    func names() {
        #expect(EdgeRating.allCases.map(\.displayName) == ["Good", "OK", "Poor"])
    }
}
