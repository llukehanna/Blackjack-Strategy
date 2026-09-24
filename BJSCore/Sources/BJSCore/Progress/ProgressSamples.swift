import Foundation

/// The trainable modules, as stored on each persisted session.
public enum TrainingModule: String, CaseIterable, Sendable, Codable {
    case strategy
    case countingRC
    case countingTC
    case shoe
}

public enum CountKind: String, Sendable, Codable {
    case runningCount = "running"
    case trueCount = "true"
}

/// One graded count check, as read back from persistence.
public struct CountSample: Sendable, Equatable {
    public let date: Date
    public let kind: CountKind
    public let expected: Double
    public let answered: Double
    public let isCorrect: Bool
    public let responseMs: Int?

    public init(date: Date, kind: CountKind, expected: Double, answered: Double,
                isCorrect: Bool, responseMs: Int?) {
        self.date = date
        self.kind = kind
        self.expected = expected
        self.answered = answered
        self.isCorrect = isCorrect
        self.responseMs = responseMs
    }
}

/// A persisted session's cached summary.
public struct SessionSample: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let module: TrainingModule
    public let startedAt: Date
    public let decisionCount: Int
    public let correctDecisions: Int
    public let countChecks: Int
    public let correctCountChecks: Int

    public init(id: UUID, module: TrainingModule, startedAt: Date, decisionCount: Int,
                correctDecisions: Int, countChecks: Int, correctCountChecks: Int) {
        self.id = id
        self.module = module
        self.startedAt = startedAt
        self.decisionCount = decisionCount
        self.correctDecisions = correctDecisions
        self.countChecks = countChecks
        self.correctCountChecks = correctCountChecks
    }
}
