import Testing
@testable import BJSCore

@Suite("Strategy rule options and named cells")
struct StrategyRulesTests {

    private func hand(_ ranks: [Rank]) -> BlackjackHand {
        BlackjackHand(cards: ranks.map { Card(rank: $0, suit: .clubs) })
    }

    private func rules(decks: BlackjackRules.DeckCount = .six, h17: Bool = false, das: Bool = true,
                       surrender: BlackjackRules.SurrenderRule = .none,
                       double: BlackjackRules.DoubleRestriction = .anyTwo,
                       peek: BlackjackRules.PeekRule = .americanPeek) -> BlackjackRules {
        var r = BlackjackRules()
        r.deckCount = decks
        r.dealerSoft17 = h17 ? .hits : .stands
        r.doubleAfterSplit = das
        r.surrenderRule = surrender
        r.doubleRestriction = double
        r.peekRule = peek
        return r
    }

    // MARK: Named spot checks (cells the old engine got wrong)

    @Test("6D S17: hard 16 vs 10 hits; soft 13 vs 5 and soft 15 vs 4 double")
    func sixDeckSpotChecks() {
        let table = StrategyEngine().strategy(for: rules())
        #expect(table.hardCells[16 - 5][Rank.ten.columnIndex] == [.hit])
        #expect(table.softCells[13 - 13][Rank.five.columnIndex] == [.double, .hit])
        #expect(table.softCells[15 - 13][Rank.four.columnIndex] == [.double, .hit])
    }

    @Test("European no hole card: 11 vs 10 and 11 vs A hit")
    func europeanElevenHits() {
        let table = StrategyEngine().strategy(for: RulePreset.europeanNoHoleCard.rules)
        #expect(table.hardCells[11 - 5][Rank.ten.columnIndex] == [.hit])
        #expect(table.hardCells[11 - 5][Rank.ace.columnIndex] == [.hit])
    }

    @Test("4 and 8 decks use the same chart as 6")
    func fourPlusDecksShareChart() {
        let engine = StrategyEngine()
        let six = engine.strategy(for: rules(decks: .six))
        #expect(engine.strategy(for: rules(decks: .four)) == six)
        #expect(engine.strategy(for: rules(decks: .eight)) == six)
    }

    // MARK: Pair rows

    @Test("1D S17 DAS: 7,7 vs 10 stands, although hard 14 vs 10 hits")
    func pairRowBeatsTotalRow() {
        let table = StrategyEngine().strategy(for: rules(decks: .one))
        let legal: Set<Action> = [.hit, .stand, .double, .split]
        #expect(table.action(for: hand([.seven, .seven]), dealerUpcard: .ten, legal: legal) == .stand)
        #expect(table.action(for: hand([.ten, .four]), dealerUpcard: .ten, legal: legal) == .hit)
    }

    @Test("1D S17 DAS: 7,7 vs 10 hits like hard 14 vs 10 once split is not legal")
    func pairRowIgnoredWhenSplitNotLegal() {
        let table = StrategyEngine().strategy(for: rules(decks: .one))
        let legal: Set<Action> = [.hit, .stand, .double]
        #expect(table.action(for: hand([.seven, .seven]), dealerUpcard: .ten, legal: legal) == .hit)
    }

    @Test("1D S17 DAS: every two-card pair uses the pair row only while split is legal")
    func pairRowAppliesOnlyWhenSplitLegal() {
        let table = StrategyEngine().strategy(for: rules(decks: .one))
        let ranks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]
        let legalSets: [Set<Action>] = [[.hit, .stand, .double], [.hit, .stand, .double, .split]]
        for rank in ranks {
            for upcard in ranks {
                let pairHand = hand([rank, rank])
                let col = upcard.columnIndex
                for legal in legalSets {
                    let spot = DecisionSpot(hand: pairHand, dealerUpcard: upcard, legalActions: legal)
                    let actual = table.action(for: spot)
                    let expected: Action
                    if legal.contains(.split) {
                        expected = table.pairCells[pairHand.pairIndex][col].first(where: legal.contains) ?? .stand
                    } else if pairHand.isSoft && pairHand.total == 12 {
                        expected = legal.contains(.hit) ? .hit : .stand
                    } else {
                        let row = pairHand.isSoft ? table.softCells[pairHand.softIndex][col] : table.hardCells[pairHand.hardIndex][col]
                        expected = row.first(where: legal.contains) ?? .stand
                    }
                    #expect(actual == expected, "\(rank) pair vs \(upcard), legal=\(legal)")
                }
            }
        }
    }

    // MARK: Soft 12 (unsplittable A,A)

    @Test("6D: A,A (soft 12) hits vs 5 when hit is legal, not the clamped soft-13 double row")
    func softTwelveHitsSixDeck() {
        let table = StrategyEngine().strategy(for: rules(decks: .six))
        let legal: Set<Action> = [.hit, .stand, .double]
        #expect(table.action(for: hand([.ace, .ace]), dealerUpcard: .five, legal: legal) == .hit)
    }

    @Test("1D: A,A (soft 12) hits vs 4 when hit is legal, not the clamped soft-13 double row")
    func softTwelveHitsOneDeck() {
        let table = StrategyEngine().strategy(for: rules(decks: .one))
        let legal: Set<Action> = [.hit, .stand, .double]
        #expect(table.action(for: hand([.ace, .ace]), dealerUpcard: .four, legal: legal) == .hit)
    }

    @Test("A,A (soft 12) falls back to stand, which is legal, when hit is not legal")
    func softTwelveFallsBackToStandWhenHitIllegal() {
        let table = StrategyEngine().strategy(for: rules(decks: .six))
        let legal: Set<Action> = [.stand, .double]
        let action = table.action(for: hand([.ace, .ace]), dealerUpcard: .five, legal: legal)
        #expect(action == .stand)
        #expect(legal.contains(action))
    }

    // MARK: Rules-view lookup

    @Test("Two-card lookup offers surrender only when the rules allow it")
    func rulesViewLookup() {
        let none = rules()
        #expect(StrategyEngine().strategy(for: none)
            .action(for: hand([.ten, .six]), dealerUpcard: .ten, rules: none) == .hit)
        let late = rules(surrender: .late)
        #expect(StrategyEngine().strategy(for: late)
            .action(for: hand([.ten, .six]), dealerUpcard: .ten, rules: late) == .surrender)
    }

    // MARK: Early surrender (American peek)

    @Test("Early surrender vs A: hard 5-7 and 12-17, pairs 3,3 6,6 7,7 8,8")
    func earlySurrenderVsAce() {
        let table = StrategyEngine().strategy(for: rules(surrender: .early))
        let ace = Rank.ace.columnIndex
        for total in [5, 6, 7, 12, 13, 14, 15, 16, 17] {
            #expect(table.hardCells[total - 5][ace].first == .surrender, "hard \(total)")
        }
        for total in [8, 9, 10, 11, 18] {
            #expect(table.hardCells[total - 5][ace].first != .surrender, "hard \(total)")
        }
        #expect(table.hardCells[17 - 5][ace] == [.surrender, .stand])
        for pairIndex in [1, 4, 5, 6] {  // 3,3 6,6 7,7 8,8
            #expect(table.pairCells[pairIndex][ace].first == .surrender, "pair index \(pairIndex)")
        }
        #expect(table.pairCells[6][ace] == [.surrender, .split])
        #expect(table.pairCells[0][ace].first != .surrender)  // 2,2 only under H17
        #expect(table.softCells.allSatisfy { $0[ace].first != .surrender })
    }

    @Test("Early surrender vs A: 2,2 surrenders when the dealer hits soft 17")
    func earlySurrenderTwosH17() {
        let table = StrategyEngine().strategy(for: rules(h17: true, surrender: .early))
        #expect(table.pairCells[0][Rank.ace.columnIndex].first == .surrender)
    }

    @Test("Early surrender vs 10: hard 14-16, pairs 7,7 and 8,8")
    func earlySurrenderVsTen() {
        let table = StrategyEngine().strategy(for: rules(surrender: .early))
        let ten = Rank.ten.columnIndex
        #expect(table.hardCells[14 - 5][ten] == [.surrender, .hit])
        #expect(table.hardCells[15 - 5][ten] == [.surrender, .hit])
        #expect(table.hardCells[16 - 5][ten] == [.surrender, .hit])
        #expect(table.hardCells[13 - 5][ten] == [.hit])
        #expect(table.hardCells[17 - 5][ten] == [.stand])
        #expect(table.pairCells[5][ten].first == .surrender)  // 7,7
        #expect(table.pairCells[6][ten] == [.surrender, .split])  // 8,8
    }

    @Test("Early surrender, 1-2 decks: no surrender of hard 14 vs 10",
          arguments: [BlackjackRules.DeckCount.one, .two])
    func earlySurrenderFewDecksFourteen(decks: BlackjackRules.DeckCount) {
        let table = StrategyEngine().strategy(for: rules(decks: decks, surrender: .early))
        #expect(table.hardCells[14 - 5][Rank.ten.columnIndex] == [.hit])
        #expect(table.hardCells[15 - 5][Rank.ten.columnIndex].first == .surrender)
    }

    @Test("Early surrender, 1 deck: 8,8 vs 10 surrenders only without DAS")
    func earlySurrenderSingleDeckEights() {
        let engine = StrategyEngine()
        let withDAS = engine.strategy(for: rules(decks: .one, das: true, surrender: .early))
        let noDAS = engine.strategy(for: rules(decks: .one, das: false, surrender: .early))
        #expect(withDAS.pairCells[6][Rank.ten.columnIndex] == [.split])
        #expect(noDAS.pairCells[6][Rank.ten.columnIndex] == [.surrender, .split])
    }

    @Test("Early surrender matches late surrender against dealer 2-9",
          arguments: [BlackjackRules.DeckCount.one, .two, .six])
    func earlyMatchesLateAgainstTwoToNine(decks: BlackjackRules.DeckCount) {
        let engine = StrategyEngine()
        let early = engine.strategy(for: rules(decks: decks, surrender: .early))
        let late = engine.strategy(for: rules(decks: decks, surrender: .late))
        let earlyCells = early.hardCells + early.softCells + early.pairCells
        let lateCells = late.hardCells + late.softCells + late.pairCells
        for row in earlyCells.indices {
            #expect(Array(earlyCells[row][0..<8]) == Array(lateCells[row][0..<8]), "row \(row)")
        }
    }

    @Test("European + early surrender follows the chart (same as late)")
    func europeanEarlyEqualsLate() {
        let engine = StrategyEngine()
        #expect(engine.strategy(for: rules(surrender: .early, peek: .europeanNoPeek))
            == engine.strategy(for: rules(surrender: .late, peek: .europeanNoPeek)))
    }

    // MARK: Double restriction

    @Test("Double 10-11 only: other doubles fall back to hit or stand")
    func doubleTenToEleven() {
        let table = StrategyEngine().strategy(for: rules(double: .tenToEleven))
        #expect(table.hardCells[9 - 5][Rank.three.columnIndex] == [.hit])
        #expect(table.hardCells[10 - 5][Rank.nine.columnIndex] == [.double, .hit])
        #expect(table.softCells[18 - 13][Rank.three.columnIndex] == [.stand])
        #expect(table.pairCells[3][Rank.six.columnIndex] == [.double, .hit])  // 5,5 = 10
        #expect(table.softCells.flatMap { $0 }.allSatisfy { !$0.contains(.double) })
    }

    @Test("Double 9-11 only: hard 9 vs 3 still doubles, soft 18 vs 3 stands")
    func doubleNineToEleven() {
        let table = StrategyEngine().strategy(for: rules(double: .nineToEleven))
        #expect(table.hardCells[9 - 5][Rank.three.columnIndex] == [.double, .hit])
        #expect(table.softCells[18 - 13][Rank.three.columnIndex] == [.stand])
    }

    @Test("Two-card lookup under a double restriction stands on soft 18 vs 3")
    func rulesViewLookupRestricted() {
        let restricted = rules(double: .tenToEleven)
        #expect(StrategyEngine().strategy(for: restricted)
            .action(for: hand([.ace, .seven]), dealerUpcard: .three, rules: restricted) == .stand)
    }

    // MARK: Decoded table shape invariant

    @Test("Decoded tables always have complete, non-empty grids whose hard/soft lists end in hit or stand")
    func decodedTableShapeInvariant() {
        let engine = StrategyEngine()
        var rulesToCheck: [BlackjackRules] = RulePreset.allCases.map { $0.rules }
        var extra = BlackjackRules()
        extra.surrenderRule = .early
        extra.doubleRestriction = .tenToEleven
        rulesToCheck.append(extra)

        for r in rulesToCheck {
            let table = engine.strategy(for: r)

            #expect(table.hardCells.count == 17)
            #expect(table.hardCells.allSatisfy { $0.count == 10 })
            #expect(table.softCells.count == 9)
            #expect(table.softCells.allSatisfy { $0.count == 10 })
            #expect(table.pairCells.count == 10)
            #expect(table.pairCells.allSatisfy { $0.count == 10 })

            #expect(table.hardCells.allSatisfy { row in row.allSatisfy { !$0.isEmpty } })
            #expect(table.softCells.allSatisfy { row in row.allSatisfy { !$0.isEmpty } })
            #expect(table.pairCells.allSatisfy { row in row.allSatisfy { !$0.isEmpty } })

            #expect(table.hardCells.allSatisfy { row in row.allSatisfy { $0.last == .hit || $0.last == .stand } })
            #expect(table.softCells.allSatisfy { row in row.allSatisfy { $0.last == .hit || $0.last == .stand } })
        }
    }

    @Test("StrategyTable.init is internal, not a public API")
    func initIsInternal() {
        // Compiles only because this test target has @testable import BJSCore access
        // to StrategyTable's memberwise init, which is `internal`, not `public`.
        let table = StrategyTable(hardCells: [], softCells: [], pairCells: [])
        #expect(table.hardCells.isEmpty)
    }
}
