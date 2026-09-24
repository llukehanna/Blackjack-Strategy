import Testing
@testable import BJSCore

@Suite("Strategy fallback when preferred action is illegal")
struct StrategyFallbackTests {

    private func h17() -> BlackjackRules {
        var r = BlackjackRules()
        r.dealerSoft17 = .hits
        r.surrenderRule = .late
        return r
    }

    private func hand(_ ranks: [Rank]) -> BlackjackHand {
        BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .clubs) })
    }

    @Test("Fallback tables only contain hit or stand")
    func fallbackOnlyHitStand() {
        let table = StrategyEngine().strategy(for: h17())
        let all = table.hardHitStand.flatMap { $0 } + table.softHitStand.flatMap { $0 }
        #expect(all.allSatisfy { $0 == .hit || $0 == .stand })
        #expect(table.hardHitStand.count == 17)
        #expect(table.softHitStand.count == 9)
    }

    @Test("Two-card soft 18 vs 2 under H17 doubles when legal")
    func soft18DoublesWhenLegal() {
        let table = StrategyEngine().strategy(for: h17())
        let action = table.action(for: hand([.ace, .seven]), dealerUpcard: .two,
                                  legal: [.hit, .stand, .double])
        #expect(action == .double)
    }

    @Test("Three-card soft 18 vs 2 under H17 stands (not hit)")
    func soft18ThreeCardsStands() {
        let table = StrategyEngine().strategy(for: h17())
        let action = table.action(for: hand([.ace, .four, .three]), dealerUpcard: .two,
                                  legal: [.hit, .stand])
        #expect(action == .stand)
    }

    @Test("Three-card hard 11 vs 6 hits")
    func hard11ThreeCardsHits() {
        let table = StrategyEngine().strategy(for: h17())
        let action = table.action(for: hand([.two, .four, .five]), dealerUpcard: .six,
                                  legal: [.hit, .stand])
        #expect(action == .hit)
    }

    @Test("Hard 17 vs Ace fallback is stand")
    func hard17VsAceFallbackStand() {
        let table = StrategyEngine().strategy(for: h17())
        #expect(table.hardHitStand[17 - 5][Rank.ace.columnIndex] == .stand)
    }

    @Test("Pair splits only when split is legal")
    func pairNeedsLegalSplit() {
        let table = StrategyEngine().strategy(for: BlackjackRules())
        let eights = hand([.eight, .eight])
        #expect(table.action(for: eights, dealerUpcard: .ten, legal: [.hit, .stand, .split]) == .split)
        // Split no longer legal (max hands reached): played as hard 16 vs 10
        let noSplit = table.action(for: eights, dealerUpcard: .ten, legal: [.hit, .stand])
        #expect(noSplit == table.hardTotals[16 - 5][Rank.ten.columnIndex])
    }

    @Test("Result is always legal when stand is legal", arguments: Rank.allCases)
    func alwaysLegal(upcard: Rank) {
        let table = StrategyEngine().strategy(for: h17())
        let legalSets: [Set<Action>] = [[.stand], [.stand, .hit], [.stand, .hit, .double],
                                        [.stand, .hit, .surrender], [.stand, .split]]
        for a in Rank.allCases {
            for b in Rank.allCases {
                for legal in legalSets {
                    let action = table.action(for: hand([a, b]), dealerUpcard: upcard, legal: legal)
                    #expect(legal.contains(action))
                }
            }
        }
    }
}
