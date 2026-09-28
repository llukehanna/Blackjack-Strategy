import Testing
@testable import BJS

@MainActor
struct EdgeComponentTests {

    @Test("Bar length is the change over the scale, clamped to 0...1")
    func barFraction() {
        #expect(EdgeContributionLayout.barFraction(change: 0.25, scale: 1) == 0.25)
        #expect(EdgeContributionLayout.barFraction(change: -0.25, scale: 1) == 0.25)
        #expect(EdgeContributionLayout.barFraction(change: -1.39, scale: 1.39) == 1)
        #expect(EdgeContributionLayout.barFraction(change: 2, scale: 1) == 1)
        #expect(EdgeContributionLayout.barFraction(change: 0.1, scale: 0) == 0)
        #expect(EdgeContributionLayout.barFraction(change: 0, scale: 1) == 0)
    }
}
