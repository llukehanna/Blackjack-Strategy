import Testing
import BJSCore
@testable import BJS

@MainActor
struct EdgeTextTests {

    @Test("Headline number is the absolute edge to two decimals")
    func headlineNumber() {
        #expect(EdgeText.headlineNumber(0.63873) == "0.64%")
        #expect(EdgeText.headlineNumber(-0.03119) == "0.03%")
        #expect(EdgeText.headlineNumber(1.69824) == "1.70%")
        #expect(EdgeText.headlineNumber(0) == "0.00%")
        #expect(EdgeText.headline(isPlayerEdge: false) == "House edge")
        #expect(EdgeText.headline(isPlayerEdge: true) == "Player edge")
    }

    @Test("Edge values keep their sign with a true minus")
    func edgeValues() {
        #expect(EdgeText.edge(0.44686) == "0.45%")
        #expect(EdgeText.edge(-0.03119) == "\u{2212}0.03%")
        #expect(EdgeText.edge(-0.001) == "0.00%")
        #expect(EdgeText.edge(2.37443) == "2.37%")
    }

    @Test("Changes are signed; a change that rounds to zero has no sign")
    func signedChange() {
        #expect(EdgeText.signedChange(0.20156) == "+0.20%")
        #expect(EdgeText.signedChange(-0.19154) == "\u{2212}0.19%")
        #expect(EdgeText.signedChange(1.39477) == "+1.39%")
        #expect(EdgeText.signedChange(0.004) == "0.00%")
        #expect(EdgeText.signedChange(-0.004) == "0.00%")
    }

    @Test("Comparison line")
    func comparison() {
        #expect(EdgeText.comparison(0.21251) == "+0.21% vs your training rules")
        #expect(EdgeText.comparison(-0.2) == "\u{2212}0.20% vs your training rules")
    }

    @Test("Factor labels", arguments: [
        (EdgeFactor.decks(.one), "1 deck"),
        (.decks(.six), "6 decks"),
        (.dealerHitsSoft17, "Dealer hits soft 17"),
        (.payout(.sixToFive), "Blackjack pays 6:5"),
        (.payout(.twoToOne), "Blackjack pays 2:1"),
        (.noDoubleAfterSplit, "No double after split"),
        (.doubleRestriction(.nineToEleven), "Double on 9–11 only"),
        (.doubleRestriction(.tenToEleven), "Double on 10–11 only"),
        (.maxSplitHands(2), "Split to 2 hands"),
        (.maxSplitHands(3), "Split to 3 hands"),
        (.resplitAces, "Resplit aces"),
        (.hitSplitAces, "Hit split aces"),
        (.noHoleCard, "No hole card"),
        (.surrender(.late, pricedAsEarly: false), "Late surrender"),
        (.surrender(.late, pricedAsEarly: true), "Late surrender (settles as early)"),
        (.surrender(.early, pricedAsEarly: false), "Early surrender"),
    ])
    func labels(_ factor: EdgeFactor, _ expected: String) {
        #expect(EdgeText.label(for: factor) == expected)
    }

    @Test("VoiceOver describes the direction and size of each change")
    func accessibility() {
        #expect(EdgeText.accessibility(for: .dealerHitsSoft17, change: 0.20156)
                == "Dealer hits soft 17, raises the house edge by 0.20 percent")
        #expect(EdgeText.accessibility(for: .decks(.two), change: -0.19154)
                == "2 decks, lowers the house edge by 0.19 percent")
        #expect(EdgeText.accessibility(for: .maxSplitHands(3), change: 0.001)
                == "Split to 3 hands, doesn't change the house edge")
    }

    @Test("Confirmation message names the new rules")
    func confirmMessage() {
        #expect(EdgeText.confirmMessage(summary: "1D · H17 · 6:5")
                == "New drills will use 1D · H17 · 6:5. Saved sessions keep their own rules.")
    }
}
