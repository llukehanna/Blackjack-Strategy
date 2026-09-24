import Foundation
import SwiftData

/// SwiftData schema, version 1 (spec §6). Future changes add `SchemaV2` plus a
/// migration stage in `BJSMigrationPlan`; never edit these models in place once shipped.
enum SchemaV1: VersionedSchema {
    nonisolated static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    nonisolated static var models: [any PersistentModel.Type] {
        [Session.self, DecisionRecord.self, CountCheckRecord.self]
    }

    /// One finished (or partially saved) training session with its cached summary.
    @Model
    final class Session {
        var id: UUID
        /// `TrainingModule` raw value: strategy | countingRC | countingTC | shoe.
        var module: String
        var mode: String?
        var startedAt: Date
        var endedAt: Date
        /// The `BlackjackRules` the session ran under, as `RulesCoding` JSON.
        var rulesJSON: Data

        var decisionCount: Int
        var correctDecisions: Int
        var countChecks: Int
        var correctCountChecks: Int
        var bestStreak: Int
        var meanResponseMs: Double?

        @Relationship(deleteRule: .cascade, inverse: \DecisionRecord.session)
        var decisions: [DecisionRecord] = []

        /// Named `countCheckRecords` because the spec's cached `countChecks: Int` already uses that name.
        @Relationship(deleteRule: .cascade, inverse: \CountCheckRecord.session)
        var countCheckRecords: [CountCheckRecord] = []

        init(id: UUID = UUID(), module: String, mode: String? = nil, startedAt: Date, endedAt: Date,
             rulesJSON: Data, decisionCount: Int = 0, correctDecisions: Int = 0, countChecks: Int = 0,
             correctCountChecks: Int = 0, bestStreak: Int = 0, meanResponseMs: Double? = nil) {
            self.id = id
            self.module = module
            self.mode = mode
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.rulesJSON = rulesJSON
            self.decisionCount = decisionCount
            self.correctDecisions = correctDecisions
            self.countChecks = countChecks
            self.correctCountChecks = correctCountChecks
            self.bestStreak = bestStreak
            self.meanResponseMs = meanResponseMs
        }
    }

    /// One graded strategy decision.
    @Model
    final class DecisionRecord {
        var handNumber: Int
        /// `HandType` raw value: hard | soft | pair.
        var handType: String
        /// Hard/soft total, or the pair's rank value (2...11, 11 = aces), as in `TrainingCell`.
        var playerValue: Int
        /// 2...11, where 11 = ace, as in `TrainingCell`.
        var dealerUpcard: Int
        /// `Action` raw value, or "timeout".
        var chosenAction: String
        var correctAction: String
        var isCorrect: Bool
        var responseMs: Int?
        /// When the decision was made. Copied into `DecisionSample.date`; never the session's start.
        var decidedAt: Date
        var session: Session?

        init(handNumber: Int, handType: String, playerValue: Int, dealerUpcard: Int,
             chosenAction: String, correctAction: String, isCorrect: Bool, responseMs: Int?,
             decidedAt: Date) {
            self.handNumber = handNumber
            self.handType = handType
            self.playerValue = playerValue
            self.dealerUpcard = dealerUpcard
            self.chosenAction = chosenAction
            self.correctAction = correctAction
            self.isCorrect = isCorrect
            self.responseMs = responseMs
            self.decidedAt = decidedAt
        }
    }

    /// One graded running- or true-count check.
    @Model
    final class CountCheckRecord {
        /// `CountKind` raw value: running | true.
        var kind: String
        var expected: Double
        var answered: Double
        var isCorrect: Bool
        var responseMs: Int?
        var cardsSeen: Int
        /// When the answer was given. Copied into `CountSample.date`.
        var answeredAt: Date
        var session: Session?

        init(kind: String, expected: Double, answered: Double, isCorrect: Bool, responseMs: Int?,
             cardsSeen: Int, answeredAt: Date) {
            self.kind = kind
            self.expected = expected
            self.answered = answered
            self.isCorrect = isCorrect
            self.responseMs = responseMs
            self.cardsSeen = cardsSeen
            self.answeredAt = answeredAt
        }
    }
}

/// The current model types. Code outside `Persistence/` uses these names.
typealias Session = SchemaV1.Session
typealias DecisionRecord = SchemaV1.DecisionRecord
typealias CountCheckRecord = SchemaV1.CountCheckRecord

/// Migration plan. V1 is the first shipped schema, so there are no stages yet.
enum BJSMigrationPlan: SchemaMigrationPlan {
    nonisolated static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    nonisolated static var stages: [MigrationStage] { [] }
}
