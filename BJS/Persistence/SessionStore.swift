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

    /// True when the persistent store failed to open and this session is running on an
    /// in-memory fallback (parent spec §6): sessions appear to save but are lost at relaunch.
    let isStorageDegraded: Bool

    init(context: ModelContext, isStorageDegraded: Bool = false) {
        self.context = context
        self.isStorageDegraded = isStorageDegraded
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

    /// Session modes whose decisions don't feed accuracy, streaks or weak spots (Step 3 spec §1):
    /// Learn mode shows the answer before the user chooses.
    static let statsExcludedModes: Set<String> = ["learn"]

    /// All sessions since `since` (all when nil), oldest first. `forStats` drops sessions in
    /// `statsExcludedModes`.
    func sessionSamples(forStats: Bool = true, since: Date? = nil) throws -> [SessionSample] {
        let sessions = try context.fetch(Self.sessions(since: since))
            .filter { !forStats || Self.countsForStats($0) }
            .sorted { $0.startedAt < $1.startedAt }
        return mapLogging(sessions, kind: "session") { $0.sample }
    }

    /// Decisions since `since` (all when nil) from sessions in `modules` (all when nil), chronological.
    func decisionSamples(modules: Set<TrainingModule>? = nil, forStats: Bool = true,
                         since: Date? = nil) throws -> [DecisionSample] {
        let records = try context.fetch(Self.decisions(since: since))
            .filter { Self.matches($0.session, modules) && (!forStats || Self.countsForStats($0.session)) }
            .sorted { ($0.decidedAt, $0.sequence) < ($1.decidedAt, $1.sequence) }
        return mapLogging(records, kind: "decision") { $0.sample }
    }

    /// Every session, newest first, Learn included (Step 6 spec §1: history shows what the user did).
    func historyEntries() throws -> [HistoryEntry] {
        let sessions = try context.fetch(FetchDescriptor<Session>())
            .sorted { $0.startedAt > $1.startedAt }
        return mapLogging(sessions, kind: "session") { session in
            session.sample.map { HistoryEntry(sample: $0, mode: session.mode) }
        }
    }

    /// One session with its records in the order they happened; nil when no session has `id`
    /// or its module is unknown.
    func sessionDetail(id: UUID) throws -> SessionDetail? {
        var descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let session = try context.fetch(descriptor).first, let sample = session.sample else { return nil }
        let rules: BlackjackRules
        do {
            rules = try JSONDecoder().decode(BlackjackRules.self, from: session.rulesJSON)
        } catch {
            logger.error("Session rules failed to decode; showing defaults: \(error.localizedDescription)")
            rules = BlackjackRules()
        }
        let decisions = mapLogging(session.decisions.sorted { $0.sequence < $1.sequence },
                                   kind: "decision") { $0.detail }
        let checks = mapLogging(session.countChecks.sorted { $0.sequence < $1.sequence },
                                kind: "count check") { record in
            record.sample.map { SessionDetail.Check(sample: $0, cardsSeen: record.cardsSeen) }
        }
        return SessionDetail(sample: sample, mode: session.mode, rules: rules,
                             bestStreak: session.bestStreak, meanResponseMs: session.meanResponseMs,
                             decisions: decisions, checks: checks)
    }

    private static func sessions(since: Date?) -> FetchDescriptor<Session> {
        guard let since else { return FetchDescriptor<Session>() }
        return FetchDescriptor<Session>(predicate: #Predicate { $0.startedAt >= since })
    }

    private static func decisions(since: Date?) -> FetchDescriptor<DecisionRecord> {
        guard let since else { return FetchDescriptor<DecisionRecord>() }
        return FetchDescriptor<DecisionRecord>(predicate: #Predicate { $0.decidedAt >= since })
    }

    /// Count checks from sessions in `modules` (all when nil), chronological.
    func countSamples(modules: Set<TrainingModule>? = nil, forStats: Bool = true) throws -> [CountSample] {
        let records = try context.fetch(FetchDescriptor<CountCheckRecord>())
            .filter { Self.matches($0.session, modules) && (!forStats || Self.countsForStats($0.session)) }
            .sorted { ($0.checkedAt, $0.sequence) < ($1.checkedAt, $1.sequence) }
        return mapLogging(records, kind: "count check") { $0.sample }
    }

    private static func countsForStats(_ session: Session?) -> Bool {
        guard let mode = session?.mode else { return true }
        return !statsExcludedModes.contains(mode)
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
