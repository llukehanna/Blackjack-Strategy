import Testing
@testable import BJSCore

struct EarlySurrenderCompositionTests {

    func rules(_ decks: BlackjackRules.DeckCount, surrender: BlackjackRules.SurrenderRule = .early,
               peek: BlackjackRules.PeekRule = .americanPeek) -> BlackjackRules {
        var r = BlackjackRules()
        r.deckCount = decks
        r.surrenderRule = surrender
        r.peekRule = peek
        return r
    }

    func hand(_ a: Rank, _ b: Rank) -> BlackjackHand {
        BlackjackHand(cards: [Card(rank: a, suit: .spades), Card(rank: b, suit: .hearts)])
    }

    let firstDecision: Set<Action> = [.hit, .stand, .double, .surrender]

    @Test("Single deck: surrender 8+6 vs 10, hit 10+4 and 9+5",
          arguments: [(Rank.eight, Rank.six, Action.surrender), (.six, .eight, .surrender),
                      (.ten, .four, .hit), (.king, .four, .hit), (.nine, .five, .hit)])
    func singleDeck(a: Rank, b: Rank, expected: Action) {
        let table = WoOChartDecoder.table(for: rules(.one))
        #expect(table.action(for: hand(a, b), dealerUpcard: .king, legal: firstDecision) == expected)
        #expect(table.action(for: hand(a, b), dealerUpcard: .ten, legal: firstDecision) == expected)
    }

    @Test("Double deck: surrender 9+5 and 8+6 vs 10, hit 10+4",
          arguments: [(Rank.eight, Rank.six, Action.surrender), (.nine, .five, .surrender),
                      (.ten, .four, .hit), (.queen, .four, .hit)])
    func doubleDeck(a: Rank, b: Rank, expected: Action) {
        let table = WoOChartDecoder.table(for: rules(.two))
        #expect(table.action(for: hand(a, b), dealerUpcard: .jack, legal: firstDecision) == expected)
    }

    @Test("Six decks: every hard 14 surrenders vs 10 (chart unchanged)",
          arguments: [(Rank.ten, Rank.four), (.nine, .five), (.eight, .six)])
    func sixDeck(a: Rank, b: Rank) {
        let table = WoOChartDecoder.table(for: rules(.six))
        #expect(table.hard14VsTenSurrenders == nil)
        #expect(table.action(for: hand(a, b), dealerUpcard: .ten, legal: firstDecision) == .surrender)
    }

    @Test("The note needs early surrender under American peek")
    func onlyEarlyPeek() {
        #expect(WoOChartDecoder.table(for: rules(.one, surrender: .late)).hard14VsTenSurrenders == nil)
        #expect(WoOChartDecoder.table(for: rules(.one, surrender: .none)).hard14VsTenSurrenders == nil)
        #expect(WoOChartDecoder.table(for: rules(.one, peek: .europeanNoPeek)).hard14VsTenSurrenders == nil)
        #expect(WoOChartDecoder.table(for: rules(.one)).hard14VsTenSurrenders == [[6, 8]])
        #expect(WoOChartDecoder.table(for: rules(.two)).hard14VsTenSurrenders == [[5, 9], [6, 8]])
    }

    @Test("Other upcards, three-card 14s and surrender-illegal spots are unaffected")
    func unaffected() {
        let table = WoOChartDecoder.table(for: rules(.one))
        let chartVsAce = table.hardCells[9][9].first(where: firstDecision.contains)
        #expect(table.action(for: hand(.eight, .six), dealerUpcard: .ace, legal: firstDecision) == chartVsAce)
        let threeCard = BlackjackHand(cards: [Card(rank: .four, suit: .spades), Card(rank: .five, suit: .hearts),
                                              Card(rank: .five, suit: .clubs)])
        #expect(table.action(for: threeCard, dealerUpcard: .ten, legal: [.hit, .stand]) == .hit)
        #expect(table.action(for: hand(.eight, .six), dealerUpcard: .ten, legal: [.hit, .stand]) == .hit)
    }

    @Test("7,7 vs 10 is graded on its pair row (surrender)")
    func sevensUsePairRow() {
        let table = WoOChartDecoder.table(for: rules(.one))
        #expect(table.action(for: hand(.seven, .seven), dealerUpcard: .ten,
                             legal: firstDecision.union([.split])) == .surrender)
    }

    @Test("compositionNoteApplies only to two-card non-pair hard 14 vs ten-value under the note")
    func noteApplies() {
        let one = WoOChartDecoder.table(for: rules(.one))
        #expect(one.compositionNoteApplies(to: hand(.ten, .four), dealerUpcard: .king))
        #expect(one.compositionNoteApplies(to: hand(.eight, .six), dealerUpcard: .ten))
        #expect(!one.compositionNoteApplies(to: hand(.eight, .six), dealerUpcard: .ace))
        #expect(!one.compositionNoteApplies(to: hand(.seven, .seven), dealerUpcard: .ten))
        #expect(!one.compositionNoteApplies(to: hand(.ten, .five), dealerUpcard: .ten))
        #expect(!WoOChartDecoder.table(for: rules(.six)).compositionNoteApplies(to: hand(.ten, .four), dealerUpcard: .ten))
    }

    @Test("preferences returns the graded row: pair row only while split is legal")
    func preferencesRow() {
        let table = WoOChartDecoder.table(for: BlackjackRules())
        let eights = hand(.eight, .eight)
        #expect(table.preferences(for: eights, dealerUpcard: .six, legal: [.hit, .stand, .split]).first == .split)
        #expect(table.preferences(for: eights, dealerUpcard: .six, legal: [.hit, .stand])
                == table.hardCells[11][4])
        let aces = hand(.ace, .ace)
        #expect(table.preferences(for: aces, dealerUpcard: .six, legal: [.hit, .stand]) == [.hit, .stand])
    }
}
