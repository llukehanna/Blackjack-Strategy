import Foundation
import Observation
import os
import SwiftData
import BJSCore

/// Saves finished sessions and reads them back as BJSCore samples.
/// Errors are thrown; callers show a non-blocking alert (parent spec §6).
@Observable
final class SessionStore {
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "SessionStore")

    /// Increments after every successful save or delete.
    private(set) var revision = 0

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ draft: SessionDraft) throws {
        let summary = SessionSummary(decisions: draft.decisions.map { ($0.isCorrect, $0.responseMs) },
                                     countChecks: draft.countChecks.map { $0.isCorrect })
        let session = Session(id: draft.id, module: draft.module.rawValue, mode: draft.mode,
                              startedAt: draft.startedAt, endedAt: draft.endedAt,
                              rulesJSON: try JSONEncoder().encode(draft.rules),
                              decisionCount: summary.decisionCount,
                              correctDecisions: summary.correctDecisions,
                              countCheckCount: summary.countCheckCount,
                              correctCountChecks: summary.correctCountChecks,
                              bestStreak: summary.bestStreak,
                              meanResponseMs: summary.meanResponseMs)
        context.insert(session)
        for (index, d) in draft.decisions.enumerated() {
            session.decisions.append(DecisionRecord(
                sequence: index, decidedAt: d.decidedAt, handNumber: d.handNumber,
                handType: d.cell.handType.rawValue, playerValue: d.cell.playerValue,
                dealerUpcard: d.cell.dealerUpcard, chosenAction: d.chosen.rawValue,
                correctAction: d.correctAction.rawValue, isCorrect: d.isCorrect, responseMs: d.responseMs))
        }
        for (index, c) in draft.countChecks.enumerated() {
            session.countChecks.append(CountCheckRecord(
                sequence: index, checkedAt: c.checkedAt, kind: c.kind.rawValue, expected: c.expected,
                answered: c.answered, isCorrect: c.isCorrect, responseMs: c.responseMs,
                cardsSeen: c.cardsSeen))
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        revision += 1
    }

    /// All sessions, oldest first.
    func sessionSamples() throws -> [SessionSample] {
        let sessions = try context.fetch(FetchDescriptor<Session>()).sorted { $0.startedAt < $1.startedAt }
        return mapLogging(sessions, kind: "session") { $0.sample }
    }

    /// Decisions from sessions in `modules` (all when nil), chronological.
    func decisionSamples(modules: Set<TrainingModule>? = nil) throws -> [DecisionSample] {
        let records = try context.fetch(FetchDescriptor<DecisionRecord>())
            .filter { Self.matches($0.session, modules) }
            .sorted { ($0.decidedAt, $0.sequence) < ($1.decidedAt, $1.sequence) }
        return mapLogging(records, kind: "decision") { $0.sample }
    }

    /// Count checks from sessions in `modules` (all when nil), chronological.
    func countSamples(modules: Set<TrainingModule>? = nil) throws -> [CountSample] {
        let records = try context.fetch(FetchDescriptor<CountCheckRecord>())
            .filter { Self.matches($0.session, modules) }
            .sorted { ($0.checkedAt, $0.sequence) < ($1.checkedAt, $1.sequence) }
        return mapLogging(records, kind: "count check") { $0.sample }
    }

    /// Deletes every session and record. Rules and preferences live elsewhere and are untouched.
    func deleteAll() throws {
        for session in try context.fetch(FetchDescriptor<Session>()) { context.delete(session) }
        for record in try context.fetch(FetchDescriptor<DecisionRecord>()) { context.delete(record) }
        for record in try context.fetch(FetchDescriptor<CountCheckRecord>()) { context.delete(record) }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        revision += 1
    }

    private static func matches(_ session: Session?, _ modules: Set<TrainingModule>?) -> Bool {
        guard let modules else { return true }
        guard let raw = session?.module, let module = TrainingModule(rawValue: raw) else { return false }
        return modules.contains(module)
    }

    private func mapLogging<Record, Sample>(_ records: [Record], kind: String,
                                            _ transform: (Record) -> Sample?) -> [Sample] {
        let samples = records.compactMap(transform)
        let dropped = records.count - samples.count
        if dropped > 0 {
            logger.error("Skipped \(dropped) \(kind) row(s) with unknown raw values")
        }
        return samples
    }
}
