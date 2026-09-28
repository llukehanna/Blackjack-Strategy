import Testing
@testable import BJSCore

struct HeatMapTests {

    func heat(_ errors: Int, of attempts: Int) -> HeatCell {
        ProgressStats.heatMap((0..<attempts).map { i in
            DecisionSample(date: .distantPast, cell: TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10),
                           isCorrect: i >= errors, responseMs: nil)
        }).values.first!
    }

    @Test("Fewer than 3 samples, or no cell, is insufficient")
    func insufficient() {
        #expect(HeatBin(nil) == .insufficient)
        #expect(HeatBin(heat(0, of: 2)) == .insufficient)
        #expect(HeatBin(heat(2, of: 2)) == .insufficient)
    }

    @Test("Bins follow the spec's edges; an edge rate belongs to the lower bin")
    func edges() {
        #expect(HeatBin(heat(0, of: 5)) == .none)
        #expect(HeatBin(heat(1, of: 20)) == .low)       // 5%
        #expect(HeatBin(heat(3, of: 20)) == .low)       // 15%, edge
        #expect(HeatBin(heat(4, of: 20)) == .medium)    // 20%
        #expect(HeatBin(heat(3, of: 10)) == .medium)    // 30%, edge
        #expect(HeatBin(heat(7, of: 20)) == .high)      // 35%
        #expect(HeatBin(heat(1, of: 4)) == .medium)      // 25%
        #expect(HeatBin(heat(5, of: 10)) == .high)      // 50%, edge
        #expect(HeatBin(heat(11, of: 20)) == .severe)   // 55%
        #expect(HeatBin(heat(3, of: 3)) == .severe)
    }

    @Test("Standard rows: hard 5–20, soft 13–20, pairs 2–A")
    func standardRows() {
        #expect(HeatMapLayout.rows(for: .hard, cells: [:]) == Array(5...20))
        #expect(HeatMapLayout.rows(for: .soft, cells: [:]) == Array(13...20))
        #expect(HeatMapLayout.rows(for: .pair, cells: [:]) == Array(2...11))
        #expect(HeatMapLayout.upcards == Array(2...11))
    }

    @Test("Hard 4 and soft 12 rows appear only when they have a decision")
    func rareRows() {
        let one = HeatCell(attempts: 1, errors: 0, errorRate: nil)
        let cells: [TrainingCell: HeatCell] = [
            TrainingCell(handType: .hard, playerValue: 4, dealerUpcard: 5): one,
            TrainingCell(handType: .soft, playerValue: 12, dealerUpcard: 11): one,
        ]
        #expect(HeatMapLayout.rows(for: .hard, cells: cells) == [4] + Array(5...20))
        #expect(HeatMapLayout.rows(for: .soft, cells: cells) == [12] + Array(13...20))
        #expect(HeatMapLayout.rows(for: .pair, cells: cells) == Array(2...11))
    }
}
