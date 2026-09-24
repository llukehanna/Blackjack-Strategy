import Foundation
import Testing
@testable import BJSCore

@Suite("WeakSpotWeights")
struct WeakSpotWeightsTests {

    let weak = TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9)
    let strong = TrainingCell(handType: .hard, playerValue: 20, dealerUpcard: 6)
    let unseen = TrainingCell(handType: .pair, playerValue: 9, dealerUpcard: 7)

    func sample(_ cell: TrainingCell, correct: Bool, at seconds: Double) -> DecisionSample {
        DecisionSample(date: Date(timeIntervalSince1970: seconds), cell: cell,
                       isCorrect: correct, responseMs: nil)
    }

    @Test("Fewer than 50 decisions returns nil (uniform)")
    func tooLittleHistory() {
        let samples = (0..<49).map { sample(strong, correct: true, at: Double($0)) }
        #expect(WeakSpotWeights.compute(from: samples) == nil)
    }

    @Test("Weak cells outweigh unseen cells, which outweigh mastered cells")
    func ordering() throws {
        var samples = (0..<10).map { sample(weak, correct: false, at: Double($0)) }
        samples += (0..<90).map { sample(strong, correct: true, at: Double(100 + $0)) }
        let weights = try #require(WeakSpotWeights.compute(from: samples))
        // p = 10/100 = 0.1
        #expect(abs(weights[weak]! - (10 + 0.2) / 12) < 1e-9)
        #expect(abs(weights[unseen]! - 0.1) < 1e-9)
        #expect(weights[strong]! == HandGenerator.minimumWeight)
        #expect(weights[weak]! > weights[unseen]!)
        #expect(weights[unseen]! > weights[strong]!)
        #expect(weights.count == TrainingCell.all.count)
    }

    @Test("Only the newest 500 decisions count")
    func windowIgnoresOldHistory() throws {
        let old = TrainingCell(handType: .hard, playerValue: 12, dealerUpcard: 2)
        var samples = (0..<100).map { sample(old, correct: false, at: Double($0)) }
        samples += (0..<500).map { sample(strong, correct: true, at: Double(1_000 + $0)) }
        let weights = try #require(WeakSpotWeights.compute(from: samples.shuffled()))
        #expect(weights[old]! == HandGenerator.minimumWeight)
    }

    @Test("No weight falls below the minimum")
    func floor() throws {
        let samples = (0..<200).map { sample(strong, correct: true, at: Double($0)) }
        let weights = try #require(WeakSpotWeights.compute(from: samples))
        #expect(weights.values.allSatisfy { $0 >= HandGenerator.minimumWeight })
    }
}
