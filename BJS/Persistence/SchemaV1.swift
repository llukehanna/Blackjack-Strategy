import Foundation
import SwiftData

/// SwiftData schema version 1 (parent spec §6, Step 2 spec §1 and §5).
/// Enums are stored as raw strings; `RecordMappers` converts them back.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Session.self, DecisionRecord.self, CountCheckRecord.self]
    }

    @Model
    final class Session {
        var id: UUID
        /// `TrainingModule` raw value: strategy | countingRC | countingTC | shoe.
        var module: String
        var mode: String?
        var startedAt: Date
        var endedAt: Date
        /// The `BlackjackRules` the session ran under, JSON-encoded.
        var rulesJSON: Data
        var decisionCount: Int
        var correctDecisions: Int
        var countCheckCount: Int
        var correctCountChecks: Int
        var bestStreak: Int
        var meanResponseMs: Double?

        @Relationship(deleteRule: .cascade, inverse: \DecisionRecord.session)
        var decisions: [DecisionRecord] = []
        @Relationship(deleteRule: .cascade, inverse: \CountCheckRecord.session)
        var countChecks: [CountCheckRecord] = []

        init(id: UUID, module: String, mode: String?, startedAt: Date, endedAt: Date, rulesJSON: Data,
             decisionCount: Int, correctDecisions: Int, countCheckCount: Int, correctCountChecks: Int,
             bestStreak: Int, meanResponseMs: Double?) {
            self.id = id
            self.module = module
            self.mode = mode
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.rulesJSON = rulesJSON
            self.decisionCount = decisionCount
            self.correctDecisions = correctDecisions
            self.countCheckCount = countCheckCount
            self.correctCountChecks = correctCountChecks
            self.bestStreak = bestStreak
            self.meanResponseMs = meanResponseMs
        }
    }

    @Model
    final class DecisionRecord {
        /// Order within the session, from 0.
        var sequence: Int
        var decidedAt: Date
        var handNumber: Int
        /// `HandType` raw value: hard | soft | pair.
        var handType: String
        /// Hard/soft total, or pair rank value (11 = aces).
        var playerValue: Int
        /// 2...11, 11 = ace.
        var dealerUpcard: Int
        /// `Action` raw value, or "timeout".
        var chosenAction: String
        var correctAction: String
        var isCorrect: Bool
        var responseMs: Int?
        var session: Session?

        init(sequence: Int, decidedAt: Date, handNumber: Int, handType: String, playerValue: Int,
             dealerUpcard: Int, chosenAction: String, correctAction: String, isCorrect: Bool,
             responseMs: Int?) {
            self.sequence = sequence
            self.decidedAt = decidedAt
            self.handNumber = handNumber
            self.handType = handType
            self.playerValue = playerValue
            self.dealerUpcard = dealerUpcard
            self.chosenAction = chosenAction
            self.correctAction = correctAction
            self.isCorrect = isCorrect
            self.responseMs = responseMs
        }
    }

    @Model
    final class CountCheckRecord {
        var sequence: Int
        var checkedAt: Date
        /// `CountKind` raw value: running | true.
        var kind: String
        var expected: Double
        var answered: Double
        var isCorrect: Bool
        var responseMs: Int?
        var cardsSeen: Int
        var session: Session?

        init(sequence: Int, checkedAt: Date, kind: String, expected: Double, answered: Double,
             isCorrect: Bool, responseMs: Int?, cardsSeen: Int) {
            self.sequence = sequence
            self.checkedAt = checkedAt
            self.kind = kind
            self.expected = expected
            self.answered = answered
            self.isCorrect = isCorrect
            self.responseMs = responseMs
            self.cardsSeen = cardsSeen
        }
    }
}

typealias Session = SchemaV1.Session
typealias DecisionRecord = SchemaV1.DecisionRecord
typealias CountCheckRecord = SchemaV1.CountCheckRecord

enum BJSMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

enum BJSModelContainer {
    static func make(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: Schema(versionedSchema: SchemaV1.self),
                                  migrationPlan: BJSMigrationPlan.self,
                                  configurations: configuration)
    }
}
