import Foundation
import SwiftData

@Model
class TrainingSession {
    var startDate: Date
    var endDate: Date?
    var mode: String  // "learn" or "test"
    var rulesJSON: Data  // BlackjackRules encoded as JSON via JSONEncoder

    @Relationship(deleteRule: .cascade, inverse: \SessionDecision.session)
    var decisions: [SessionDecision] = []

    var totalDecisions: Int { decisions.count }
    var correctDecisions: Int { decisions.filter(\.isCorrect).count }
    var accuracyPercentage: Double {
        guard totalDecisions > 0 else { return 0 }
        return Double(correctDecisions) / Double(totalDecisions) * 100
    }
    var errorCount: Int { totalDecisions - correctDecisions }
    var bestStreak: Int {
        var maxStreak = 0
        var current = 0
        for decision in decisions.sorted(by: { $0.handNumber < $1.handNumber }) {
            if decision.isCorrect {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        return maxStreak
    }

    init(startDate: Date = Date(), mode: String, rulesJSON: Data) {
        self.startDate = startDate
        self.mode = mode
        self.rulesJSON = rulesJSON
    }
}
