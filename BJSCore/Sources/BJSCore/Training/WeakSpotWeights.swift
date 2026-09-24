import Foundation

/// One graded strategy decision, as read back from persistence.
public struct DecisionSample: Sendable, Equatable {
    public let date: Date
    public let cell: TrainingCell
    public let isCorrect: Bool
    public let responseMs: Int?

    public init(date: Date, cell: TrainingCell, isCorrect: Bool, responseMs: Int?) {
        self.date = date
        self.cell = cell
        self.isCorrect = isCorrect
        self.responseMs = responseMs
    }
}

/// Per-cell sampling weights for Weak-spots mode.
///
/// Error rate per cell over the newest `historyWindow` decisions, smoothed toward the
/// user's overall error rate p: (errors + 2p) / (attempts + 2), floored at
/// `HandGenerator.minimumWeight`. Unseen cells therefore sit at about p, below real weak spots.
public enum WeakSpotWeights {
    public static let historyWindow = 500
    public static let minimumHistory = 50

    public static func compute(from samples: [DecisionSample]) -> [TrainingCell: Double]? {
        guard samples.count >= minimumHistory else { return nil }
        let recent = samples.sorted { $0.date < $1.date }.suffix(historyWindow)

        var attempts: [TrainingCell: Int] = [:]
        var errors: [TrainingCell: Int] = [:]
        var totalErrors = 0
        for sample in recent {
            attempts[sample.cell, default: 0] += 1
            if !sample.isCorrect {
                errors[sample.cell, default: 0] += 1
                totalErrors += 1
            }
        }
        let prior = Double(totalErrors) / Double(recent.count)

        var weights: [TrainingCell: Double] = [:]
        for cell in TrainingCell.all {
            let a = Double(attempts[cell] ?? 0)
            let e = Double(errors[cell] ?? 0)
            let rate = (e + 2 * prior) / (a + 2)
            weights[cell] = max(rate, HandGenerator.minimumWeight)
        }
        return weights
    }
}
