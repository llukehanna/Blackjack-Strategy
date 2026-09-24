import BJSCore
import Foundation

/// SwiftData records → the plain `Sendable` samples `ProgressStats` and `WeakSpotWeights` use (spec §6).
///
/// Each sample's `date` is the record's own timestamp (`decidedAt`, `answeredAt`),
/// never the session's `startedAt`. Records with unknown enum strings are skipped and logged.
enum ProgressMapper {
    static func sessionSample(_ session: Session) -> SessionSample? {
        guard let module = TrainingModule(rawValue: session.module) else {
            let raw = session.module
            AppLog.persistence.error("Skipping session with unknown module '\(raw, privacy: .public)'")
            return nil
        }
        return SessionSample(id: session.id, module: module, startedAt: session.startedAt,
                             decisionCount: session.decisionCount, correctDecisions: session.correctDecisions,
                             countChecks: session.countChecks, correctCountChecks: session.correctCountChecks)
    }

    static func decisionSample(_ record: DecisionRecord) -> DecisionSample? {
        guard let handType = HandType(rawValue: record.handType) else {
            let raw = record.handType
            AppLog.persistence.error("Skipping decision with unknown hand type '\(raw, privacy: .public)'")
            return nil
        }
        let cell = TrainingCell(handType: handType, playerValue: record.playerValue,
                                dealerUpcard: record.dealerUpcard)
        return DecisionSample(date: record.decidedAt, cell: cell, isCorrect: record.isCorrect,
                              responseMs: record.responseMs)
    }

    static func countSample(_ record: CountCheckRecord) -> CountSample? {
        guard let kind = CountKind(rawValue: record.kind) else {
            let raw = record.kind
            AppLog.persistence.error("Skipping count check with unknown kind '\(raw, privacy: .public)'")
            return nil
        }
        return CountSample(date: record.answeredAt, kind: kind, expected: record.expected,
                           answered: record.answered, isCorrect: record.isCorrect,
                           responseMs: record.responseMs)
    }

    static func sessionSamples(_ sessions: [Session]) -> [SessionSample] {
        sessions.compactMap(sessionSample)
    }

    static func decisionSamples(_ records: [DecisionRecord]) -> [DecisionSample] {
        records.compactMap(decisionSample)
    }

    static func countSamples(_ records: [CountCheckRecord]) -> [CountSample] {
        records.compactMap(countSample)
    }
}
