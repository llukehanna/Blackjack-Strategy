import BJSCore
import Testing
@testable import BJS

@Suite("StrategyText")
struct StrategyTextTests {

    private func hand(_ ranks: [Rank]) -> BlackjackHand {
        BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .clubs) })
    }

    @Test("Progress reads 'Hand n of N', or 'Hand n' in Endless")
    func progress() {
        #expect(StrategyText.progress(handNumber: 3, limit: 25) == "Hand 3 of 25")
        #expect(StrategyText.progress(handNumber: 7, limit: nil) == "Hand 7")
    }

    @Test("Totals: hard, soft as low/high, 21, bust; the dealer's result")
    func totals() {
        #expect(StrategyText.total(hand([.ten, .six])) == "16")
        #expect(StrategyText.total(hand([.ace, .seven])) == "8/18")
        #expect(StrategyText.total(hand([.ace, .ten])) == "21")
        #expect(StrategyText.total(hand([.ten, .six, .nine])) == "Bust")
        #expect(StrategyText.dealerResult(hand([.ten, .nine])) == "Dealer has 19")
        #expect(StrategyText.dealerResult(hand([.ten, .six, .nine])) == "Dealer busts")
    }

    @Test("Net results use a true minus sign and drop '.0'")
    func net() {
        #expect(StrategyText.net(1) == "+1")
        #expect(StrategyText.net(-2) == "\u{2212}2")
        #expect(StrategyText.net(0) == "0")
        #expect(StrategyText.net(1.5) == "+1.5")
        #expect(StrategyText.net(-0.5) == "\u{2212}0.5")
    }

    @Test("Summary numbers")
    func summaryNumbers() {
        #expect(StrategyText.percent(nil) == "—")
        #expect(StrategyText.percent(0.875) == "88%")
        #expect(StrategyText.seconds(fromMs: nil) == "—")
        #expect(StrategyText.seconds(fromMs: 1_440) == "1.4 s")
        #expect(StrategyText.mistakeDetail(StrategyFixtures.decision(1, choice: .timeout)) == "You: Timeout · Play: Hit")
    }
}
