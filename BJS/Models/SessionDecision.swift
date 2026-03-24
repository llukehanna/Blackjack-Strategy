import Foundation
import SwiftData

@Model
class SessionDecision {
    var session: TrainingSession?
    var timestamp: Date
    var handDescription: String     // e.g. "Soft 18 vs 9"
    var playerAction: String        // Action.rawValue ("hit", "stand", etc.)
    var correctAction: String       // Action.rawValue
    var isCorrect: Bool
    var handNumber: Int             // Sequential within the session (1-based)

    init(
        timestamp: Date = Date(),
        handDescription: String,
        playerAction: String,
        correctAction: String,
        isCorrect: Bool,
        handNumber: Int
    ) {
        self.timestamp = timestamp
        self.handDescription = handDescription
        self.playerAction = playerAction
        self.correctAction = correctAction
        self.isCorrect = isCorrect
        self.handNumber = handNumber
    }
}
