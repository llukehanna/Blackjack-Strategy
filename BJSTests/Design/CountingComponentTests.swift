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

    @Test("VoiceOver rounds decks played to the shoe's true-count step")
    func accessibility() {
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 2.75, decksTotal: 6) == "About 3 decks played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 2.6, decksTotal: 6) == "About 2.5 decks played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 1, decksTotal: 6) == "About 1 deck played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 0.25, decksTotal: 6) == "About 0.5 decks played")

        // 1-deck shoes move in quarter decks.
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 0.25, decksTotal: 1) == "About 0.25 decks played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 0.75, decksTotal: 1) == "About 0.75 decks played")

        // 2-deck shoes also move in quarter decks.
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 1.75, decksTotal: 2) == "About 1.75 decks played")
        #expect(DiscardTrayLayout.accessibilityValue(decksPlayed: 1, decksTotal: 2) == "About 1 deck played")
    }
}
