import Testing
@testable import BJS

@MainActor
struct CountingComponentTests {

    @Test("Fill is decks played over the shoe, clamped")
    func fill() {
        #expect(DiscardTrayLayout.fillFraction(decksTotal: 6, decksPlayed: 1.5) == 0.25)
        #expect(DiscardTrayLayout.fillFraction(decksTotal: 6, decksPlayed: 9) == 1)
        #expect(DiscardTrayLayout.fillFraction(decksTotal: 6, decksPlayed: -1) == 0)
        #expect(DiscardTrayLayout.fillFraction(decksTotal: 0, decksPlayed: 1) == 0)
    }

    @Test("Whole-deck ticks sit between decks; none for a single deck")
    func ticks() {
        #expect(DiscardTrayLayout.tickFractions(decksTotal: 4) == [0.25, 0.5, 0.75])
        #expect(DiscardTrayLayout.tickFractions(decksTotal: 2) == [0.5])
        #expect(DiscardTrayLayout.tickFractions(decksTotal: 1).isEmpty)
    }

    @Test("VoiceOver rounds decks played to the nearest half")
    func accessibility() {
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 2.75) == "About 3 decks played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 2.6) == "About 2.5 decks played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 1) == "About 1 deck played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 0.25) == "About 0.5 decks played")
    }
}
