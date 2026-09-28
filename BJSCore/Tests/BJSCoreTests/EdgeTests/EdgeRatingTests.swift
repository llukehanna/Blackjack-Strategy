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

    @Test("Presets rate as expected on the cut-card figure")
    func presets() {
        let calc = EdgeCalculator()
        func rating(_ preset: RulePreset) -> EdgeRating { EdgeRating(houseEdge: calc.houseEdge(for: preset.rules)) }
        #expect(rating(.vegasStrip) == .good)          // 0.43%
        #expect(rating(.downtownVegas) == .good)       // 0.39%
        #expect(rating(.atlanticCity) == .good)        // 0.37%
        #expect(rating(.europeanNoHoleCard) == .ok)    // 0.54%
        #expect(rating(.singleDeckSixFive) == .poor)   // 1.70%
    }

    @Test("Display names")
    func names() {
        #expect(EdgeRating.allCases.map(\.displayName) == ["Good", "OK", "Poor"])
    }
}
