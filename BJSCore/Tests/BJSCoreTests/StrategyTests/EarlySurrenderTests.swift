import Testing
@testable import BJSCore

// Early surrender (ES): the player may surrender before the dealer checks for
// blackjack, so surrender (-0.5) must be compared with the *unconditional* EV of
// playing on, which includes losing the original bet to a dealer natural.
//
// Reference: Wizard of Odds 4-8 deck basic strategy, early-surrender variant
// (peek game, player may surrender before the peek). Each surrender cell below
// was also cross-checked against the engine's own EVs.

private func esRules(_ soft17: BlackjackRules.DealerSoft17) -> BlackjackRules {
    var r = BlackjackRules()
    r.deckCount = .six
    r.dealerSoft17 = soft17
    r.doubleAfterSplit = true
    r.surrenderRule = .early
    r.peekRule = .americanPeek
    return r
}

private func hand(_ ranks: [Rank]) -> BlackjackHand {
    BlackjackHand(cards: ranks.enumerated().map { i, rank in
        Card(rank: rank, suit: i.isMultiple(of: 2) ? .clubs : .hearts)
    })
}

/// A representative non-pair two-card hand for a hard total.
private func hardHand(_ total: Int) -> BlackjackHand {
    switch total {
    case 5: return hand([.two, .three])
    case 6: return hand([.two, .four])
    case 7: return hand([.two, .five])
    case 8: return hand([.two, .six])
    case 9: return hand([.two, .seven])
    case 10: return hand([.two, .eight])
    case 11: return hand([.two, .nine])
    default: return hand([.ten, Rank.allCases.first { $0.blackjackValue == total - 10 && $0 != .ace }!])
    }
}

private let allLegal: Set<Action> = [.hit, .stand, .double, .split, .surrender]

struct ESCell: Sendable, CustomTestStringConvertible {
    let soft17: BlackjackRules.DealerSoft17
    let hardTotal: Int
    let dealer: Rank
    let expected: Action
    var testDescription: String { "ES 6D \(soft17): hard \(hardTotal) vs \(dealer) -> \(expected)" }
}

struct ESPairCell: Sendable, CustomTestStringConvertible {
    let soft17: BlackjackRules.DealerSoft17
    let pair: Rank
    let dealer: Rank
    let expected: Action
    var testDescription: String { "ES 6D \(soft17): pair \(pair) vs \(dealer) -> \(expected)" }
}

private let esHardCells: [ESCell] = [BlackjackRules.DealerSoft17.stands, .hits].flatMap { s17 -> [ESCell] in
    // vs Ace: surrender hard 5-7 and 12-17 (WoO early surrender).
    let vsAce = [5, 6, 7, 12, 13, 14, 15, 16, 17].map {
        ESCell(soft17: s17, hardTotal: $0, dealer: .ace, expected: .surrender)
    }
    // vs 10: surrender hard 14-16 (WoO early surrender).
    let vsTen = [14, 15, 16].map {
        ESCell(soft17: s17, hardTotal: $0, dealer: .ten, expected: .surrender)
    }
    return vsAce + vsTen + [
        // vs 9: surrender hard 16 (same as late surrender; no dealer BJ possible).
        ESCell(soft17: s17, hardTotal: 16, dealer: .nine, expected: .surrender),
        // Non-surrender neighbours.
        ESCell(soft17: s17, hardTotal: 13, dealer: .ten, expected: .hit),
        ESCell(soft17: s17, hardTotal: 17, dealer: .ten, expected: .stand),
        ESCell(soft17: s17, hardTotal: 11, dealer: .ace, expected: s17 == .hits ? .double : .hit),
        ESCell(soft17: s17, hardTotal: 10, dealer: .ace, expected: .hit),
        ESCell(soft17: s17, hardTotal: 15, dealer: .nine, expected: .hit),
    ]
}

private let esPairCells: [ESPairCell] = [BlackjackRules.DealerSoft17.stands, .hits].flatMap { s17 -> [ESPairCell] in
    [
        // vs Ace: surrender 3,3 / 6,6 / 7,7 / 8,8 (WoO early surrender).
        ESPairCell(soft17: s17, pair: .three, dealer: .ace, expected: .surrender),
        ESPairCell(soft17: s17, pair: .six, dealer: .ace, expected: .surrender),
        ESPairCell(soft17: s17, pair: .seven, dealer: .ace, expected: .surrender),
        ESPairCell(soft17: s17, pair: .eight, dealer: .ace, expected: .surrender),
        // vs 10: surrender 7,7 / 8,8 (WoO early surrender).
        ESPairCell(soft17: s17, pair: .seven, dealer: .ten, expected: .surrender),
        ESPairCell(soft17: s17, pair: .eight, dealer: .ten, expected: .surrender),
        // Still split: 8,8 vs 9 and A,A vs A.
        ESPairCell(soft17: s17, pair: .eight, dealer: .nine, expected: .split),
        ESPairCell(soft17: s17, pair: .ace, dealer: .ace, expected: .split),
    ]
}

@Suite("Early surrender strategy - WoO reference")
struct EarlySurrenderTests {

    @Test("Hard totals match WoO early-surrender strategy", arguments: esHardCells)
    func hardTotals(cell: ESCell) {
        let table = StrategyEngine().strategy(for: esRules(cell.soft17))
        let h = hardHand(cell.hardTotal)
        #expect(!h.isPair && !h.isSoft && h.total == cell.hardTotal)
        #expect(table.hardTotals[cell.hardTotal - 5][cell.dealer.columnIndex] == cell.expected)
        #expect(table.action(for: h, dealerUpcard: cell.dealer, legal: allLegal) == cell.expected)
    }

    @Test("Pairs match WoO early-surrender strategy", arguments: esPairCells)
    func pairs(cell: ESPairCell) {
        let table = StrategyEngine().strategy(for: esRules(cell.soft17))
        let h = hand([cell.pair, cell.pair])
        let pairIndex = cell.pair == .ace ? 9 : cell.pair.blackjackValue - 2
        #expect(table.pairs[pairIndex][cell.dealer.columnIndex] == cell.expected)
        #expect(table.action(for: h, dealerUpcard: cell.dealer, legal: allLegal) == cell.expected)
    }

    @Test("Early surrender never surrenders soft hands vs Ace or 10")
    func softHandsNeverSurrender() {
        for s17 in [BlackjackRules.DealerSoft17.stands, .hits] {
            let table = StrategyEngine().strategy(for: esRules(s17))
            for row in table.softTotals {
                #expect(row[8] != .surrender && row[9] != .surrender)
            }
        }
    }

    @Test("Surrender is illegal after the first decision: falls back to hit/stand")
    func fallbackWithoutSurrender() {
        let table = StrategyEngine().strategy(for: esRules(.stands))
        // Hard 14 vs 10 as a three-card hand: surrender not legal -> hit.
        let three = hand([.four, .five, .five])
        #expect(table.action(for: three, dealerUpcard: .ten, legal: [.hit, .stand]) == .hit)
        // Hard 17 vs A with surrender not legal -> stand.
        let seventeen = hand([.ten, .seven])
        #expect(table.action(for: seventeen, dealerUpcard: .ace, legal: [.hit, .stand, .double]) == .stand)
    }

    @Test("Late and no-surrender tables are unchanged by the early-surrender fix")
    func lateAndNoneUnchanged() {
        var late = esRules(.stands)
        late.surrenderRule = .late
        let t = StrategyEngine().strategy(for: late)
        // WoO 4-8 deck S17 late surrender: surrender 15 v 10, 16 v 9/10/A only.
        #expect(t.hardTotals[16 - 5][Rank.nine.columnIndex] == .surrender)
        #expect(t.hardTotals[16 - 5][Rank.ten.columnIndex] == .surrender)
        #expect(t.hardTotals[16 - 5][Rank.ace.columnIndex] == .surrender)
        #expect(t.hardTotals[15 - 5][Rank.ten.columnIndex] == .surrender)
        #expect(t.hardTotals[14 - 5][Rank.ten.columnIndex] == .hit)
        #expect(t.hardTotals[15 - 5][Rank.ace.columnIndex] == .hit)
        #expect(t.hardTotals[17 - 5][Rank.ace.columnIndex] == .stand)
        #expect(t.hardTotals[7 - 5][Rank.ace.columnIndex] == .hit)
        #expect(t.pairs[6][Rank.ace.columnIndex] == .split)
        #expect(t.pairs[5][Rank.ten.columnIndex] != .surrender)

        var none = late
        none.surrenderRule = .none
        let n = StrategyEngine().strategy(for: none)
        let all = n.hardTotals.flatMap { $0 } + n.softTotals.flatMap { $0 } + n.pairs.flatMap { $0 }
        #expect(!all.contains(.surrender))
    }
}

// MARK: - ENHC late surrender

// Under European no-hole-card, "late" surrender is only offered while the dealer's
// blackjack is still unknown and a surrendered hand still loses the whole bet to a
// dealer natural (RoundEngine settles it at -1). Surrender is therefore worth
// -0.5 - 0.5 * P(BJ), not -0.5. For hands that only hit or stand this makes the
// surrender decisions identical to the peek late-surrender game.
@Suite("ENHC late surrender")
struct ENHCLateSurrenderTests {

    private func rules(_ peek: BlackjackRules.PeekRule) -> BlackjackRules {
        var r = BlackjackRules()
        r.deckCount = .six
        r.dealerSoft17 = .stands
        r.surrenderRule = .late
        r.peekRule = peek
        return r
    }

    @Test("ENHC late surrender matches peek late surrender for hard 12-17 vs 9, 10, A")
    func matchesPeekForHitStandHands() {
        let enhc = StrategyEngine().strategy(for: rules(.europeanNoPeek))
        let peek = StrategyEngine().strategy(for: rules(.americanPeek))
        for total in 12...17 {
            for up in [Rank.nine, .ten, .ace] {
                let e = enhc.hardTotals[total - 5][up.columnIndex]
                let p = peek.hardTotals[total - 5][up.columnIndex]
                #expect((e == .surrender) == (p == .surrender),
                        "hard \(total) vs \(up): ENHC \(e), peek \(p)")
            }
        }
    }

    @Test("ENHC late surrender: hard 17 vs A stands, hard 16 vs 10 surrenders")
    func enhcSpotChecks() {
        let t = StrategyEngine().strategy(for: rules(.europeanNoPeek))
        #expect(t.hardTotals[17 - 5][Rank.ace.columnIndex] == .stand)
        #expect(t.hardTotals[14 - 5][Rank.ten.columnIndex] == .hit)
        #expect(t.hardTotals[16 - 5][Rank.ten.columnIndex] == .surrender)
    }
}

// MARK: - ENHC early surrender

// Under European no-hole-card the play EVs are already unconditional, so early
// surrender is simply -0.5 against them. For hands whose alternative is hit or
// stand, the decision is then identical to peek-game early surrender (both compare
// -0.5 with an EV that loses one unit to a dealer natural), so WoO's early-surrender
// plays carry over. 8,8 vs 10/A is already a surrender under ENHC *late* surrender
// (WoO ENHC chart), so it must be one under early surrender too.
@Suite("ENHC early surrender")
struct ENHCEarlySurrenderTests {

    private func rules(_ soft17: BlackjackRules.DealerSoft17) -> BlackjackRules {
        var r = esRules(soft17)
        r.peekRule = .europeanNoPeek
        return r
    }

    @Test("ENHC ES: WoO early-surrender plays vs A and 10", arguments: [BlackjackRules.DealerSoft17.stands, .hits])
    func surrenderCells(soft17: BlackjackRules.DealerSoft17) {
        let t = StrategyEngine().strategy(for: rules(soft17))
        for total in [5, 6, 7, 12, 13, 14, 15, 16, 17] {
            #expect(t.action(for: hardHand(total), dealerUpcard: .ace, legal: allLegal) == .surrender,
                    "hard \(total) vs A")
        }
        for total in [14, 15, 16] {
            #expect(t.action(for: hardHand(total), dealerUpcard: .ten, legal: allLegal) == .surrender,
                    "hard \(total) vs 10")
        }
        for pair in [Rank.three, .six, .seven, .eight] {
            #expect(t.action(for: hand([pair, pair]), dealerUpcard: .ace, legal: allLegal) == .surrender,
                    "\(pair),\(pair) vs A")
        }
        for pair in [Rank.seven, .eight] {
            #expect(t.action(for: hand([pair, pair]), dealerUpcard: .ten, legal: allLegal) == .surrender,
                    "\(pair),\(pair) vs 10")
        }
    }

    @Test("ENHC ES: non-surrender neighbours", arguments: [BlackjackRules.DealerSoft17.stands, .hits])
    func neighbours(soft17: BlackjackRules.DealerSoft17) {
        let t = StrategyEngine().strategy(for: rules(soft17))
        #expect(t.action(for: hardHand(13), dealerUpcard: .ten, legal: allLegal) == .hit)
        #expect(t.action(for: hardHand(17), dealerUpcard: .ten, legal: allLegal) == .stand)
        #expect(t.action(for: hardHand(18), dealerUpcard: .ace, legal: allLegal) == .stand)
        #expect(t.action(for: hardHand(8), dealerUpcard: .ace, legal: allLegal) == .hit)
        for row in t.softTotals {
            #expect(row[Rank.ten.columnIndex] != .surrender && row[Rank.ace.columnIndex] != .surrender)
        }
    }

    @Test("ENHC ES matches peek ES for hit/stand hands (hard 5-7, 12-17 vs 9, 10, A)",
          arguments: [BlackjackRules.DealerSoft17.stands, .hits])
    func matchesPeekForHitStandHands(soft17: BlackjackRules.DealerSoft17) {
        let enhc = StrategyEngine().strategy(for: rules(soft17))
        let peek = StrategyEngine().strategy(for: esRules(soft17))
        for total in [5, 6, 7, 12, 13, 14, 15, 16, 17] {
            for up in [Rank.nine, .ten, .ace] {
                let e = enhc.hardTotals[total - 5][up.columnIndex]
                let p = peek.hardTotals[total - 5][up.columnIndex]
                #expect((e == .surrender) == (p == .surrender), "hard \(total) vs \(up): ENHC \(e), peek \(p)")
            }
        }
    }
}

// MARK: - Early surrender at 1 and 2 decks

// Only the cells whose early-surrender play is robust to deck count are asserted:
// hard 12-17 vs A, hard 15-16 vs 10 (both surrendered even late at every deck count
// or far past the ES threshold) and 8,8 vs A/10. The single-deck engine does not model
// the player's own cards, so composition-sensitive cells (e.g. 7,7 vs 10) are left out.
@Suite("Early surrender at 1 and 2 decks")
struct FewDeckEarlySurrenderTests {

    static let configs: [(BlackjackRules.DeckCount, BlackjackRules.DealerSoft17)] =
        [(.one, .stands), (.one, .hits), (.two, .stands), (.two, .hits)]

    private func rules(_ decks: BlackjackRules.DeckCount, _ soft17: BlackjackRules.DealerSoft17) -> BlackjackRules {
        var r = esRules(soft17)
        r.deckCount = decks
        return r
    }

    @Test("Few-deck ES: robust WoO early-surrender plays", arguments: configs)
    func surrenderCells(decks: BlackjackRules.DeckCount, soft17: BlackjackRules.DealerSoft17) {
        let t = StrategyEngine().strategy(for: rules(decks, soft17))
        for total in 12...17 {
            #expect(t.action(for: hardHand(total), dealerUpcard: .ace, legal: allLegal) == .surrender,
                    "hard \(total) vs A")
        }
        for total in [15, 16] {
            #expect(t.action(for: hardHand(total), dealerUpcard: .ten, legal: allLegal) == .surrender,
                    "hard \(total) vs 10")
        }
        for up in [Rank.ten, .ace] {
            #expect(t.action(for: hand([.eight, .eight]), dealerUpcard: up, legal: allLegal) == .surrender,
                    "8,8 vs \(up)")
        }
    }

    @Test("Few-deck ES: non-surrender neighbours", arguments: configs)
    func neighbours(decks: BlackjackRules.DeckCount, soft17: BlackjackRules.DealerSoft17) {
        let t = StrategyEngine().strategy(for: rules(decks, soft17))
        #expect(t.action(for: hardHand(13), dealerUpcard: .ten, legal: allLegal) == .hit)
        #expect(t.action(for: hardHand(17), dealerUpcard: .ten, legal: allLegal) == .stand)
        #expect(t.action(for: hardHand(18), dealerUpcard: .ace, legal: allLegal) == .stand)
        #expect(t.action(for: hand([.ace, .ace]), dealerUpcard: .ace, legal: allLegal) == .split)
        for row in t.softTotals {
            #expect(row[Rank.ten.columnIndex] != .surrender && row[Rank.ace.columnIndex] != .surrender)
        }
    }
}

// MARK: - Early surrender dominates late surrender

// Early surrender is offered in strictly more situations than late surrender and is
// worth at least as much, so every late-surrender play must also be an early one.
@Suite("Early surrender dominates late surrender")
struct EarlyDominatesLateTests {

    @Test("Every late-surrender cell is also an early-surrender cell",
          arguments: BlackjackRules.DeckCount.allCases)
    func earlySupersetOfLate(decks: BlackjackRules.DeckCount) {
        for peek in BlackjackRules.PeekRule.allCases {
            for soft17 in BlackjackRules.DealerSoft17.allCases {
                var r = esRules(soft17)
                r.deckCount = decks
                r.peekRule = peek
                let early = StrategyEngine().strategy(for: r)
                r.surrenderRule = .late
                let late = StrategyEngine().strategy(for: r)
                let pairs = [(late.hardTotals, early.hardTotals, "hard"),
                             (late.softTotals, early.softTotals, "soft"),
                             (late.pairs, early.pairs, "pair")]
                for (l, e, name) in pairs {
                    for row in l.indices {
                        for col in 0..<10 where l[row][col] == .surrender {
                            #expect(e[row][col] == .surrender,
                                    "\(decks) \(peek) \(soft17) \(name) row \(row) col \(col)")
                        }
                    }
                }
            }
        }
    }
}
