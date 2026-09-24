import Testing
@testable import BJSCore

@Suite("HandGenerator")
struct HandGeneratorTests {

    @Test("There are 340 distinct training cells")
    func cellCount() {
        #expect(TrainingCell.all.count == 340)
        #expect(Set(TrainingCell.all).count == 340)
        #expect(TrainingCell.cells(matching: .hard).count == 160)
        #expect(TrainingCell.cells(matching: .soft).count == 80)
        #expect(TrainingCell.cells(matching: .pairs).count == 100)
        #expect(TrainingCell.cells(matching: .all).count == 340)
    }

    @Test("Every cell deals a round whose first spot classifies back to that cell")
    func roundTripsEveryCell() throws {
        var rng = SeededRandomNumberGenerator(seed: 99)
        let rules = BlackjackRules()
        for cell in TrainingCell.all {
            for _ in 0..<5 {
                var shoe = HandGenerator.stackedShoe(for: cell, deckCount: 6, using: &rng)
                let round = try RoundEngine(rules: rules, shoe: &shoe)
                #expect(round.phase == .playerTurn, "cell \(cell) did not start in player turn")
                let spot = try #require(round.currentSpot)
                #expect(TrainingCell(spot: spot) == cell)
                #expect(!round.dealer.isBlackjack)
            }
        }
    }

    @Test("Single-deck stacked shoes never duplicate a card")
    func singleDeckNoDuplicates() {
        var rng = SeededRandomNumberGenerator(seed: 3)
        for cell in TrainingCell.all {
            var shoe = HandGenerator.stackedShoe(for: cell, deckCount: 1, using: &rng)
            var seen = Set<Card>()
            while let card = shoe.deal() { seen.insert(card) }
            #expect(seen.count == 52)
        }
    }

    @Test("Filter restricts sampled cells", arguments: [HandFilter.hard, .soft, .pairs])
    func filterRespected(filter: HandFilter) {
        var rng = SeededRandomNumberGenerator(seed: 11)
        let allowed = Set(TrainingCell.cells(matching: filter))
        for _ in 0..<2_000 {
            #expect(allowed.contains(HandGenerator.sampleCell(filter: filter, weights: nil, using: &rng)))
        }
    }

    @Test("Weighted sampling converges to the weight share")
    func weightedConvergence() {
        var rng = SeededRandomNumberGenerator(seed: 21)
        let heavy = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)
        var weights: [TrainingCell: Double] = [:]
        for cell in TrainingCell.all { weights[cell] = 0.05 }
        weights[heavy] = 10
        let expectedShare = 10 / (10 + 0.05 * 339)
        var hits = 0
        var seen = Set<TrainingCell>()
        let draws = 40_000
        for _ in 0..<draws {
            let cell = HandGenerator.sampleCell(filter: .all, weights: weights, using: &rng)
            seen.insert(cell)
            if cell == heavy { hits += 1 }
        }
        #expect(abs(Double(hits) / Double(draws) - expectedShare) < 0.02)
        #expect(seen.count == 340)
    }

    @Test("Zero or missing weights are clamped to the minimum, never excluded")
    func zeroWeightsClamped() {
        var rng = SeededRandomNumberGenerator(seed: 5)
        let only = TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9)
        let weights: [TrainingCell: Double] = [only: 0]
        var seen = Set<TrainingCell>()
        for _ in 0..<5_000 {
            seen.insert(HandGenerator.sampleCell(filter: .soft, weights: weights, using: &rng))
        }
        #expect(seen.count == 80)
    }

    @Test("Hard cells never produce a pair or an ace")
    func hardCellsAreHard() {
        var rng = SeededRandomNumberGenerator(seed: 8)
        for cell in TrainingCell.cells(matching: .hard) {
            let (player, _) = HandGenerator.cards(for: cell, using: &rng)
            let hand = BlackjackHand(cards: player)
            #expect(!hand.isPair)
            #expect(!hand.isSoft)
            #expect(hand.total == cell.playerValue)
        }
    }
}
