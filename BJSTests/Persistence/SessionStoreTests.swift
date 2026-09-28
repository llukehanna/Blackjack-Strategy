import Foundation
import SwiftData
import Testing
import BJSCore
@testable import BJS

@MainActor
struct SessionStoreTests {

    let container: ModelContainer  // retained: the context does not keep its container alive
    let store: SessionStore
    let context: ModelContext

    init() throws {
        container = try BJSModelContainer.make(inMemory: true)
        context = container.mainContext
        store = SessionStore(context: context)
    }

    func t(_ seconds: Double) -> Date { Date(timeIntervalSince1970: seconds) }

    func decision(_ correct: Bool, at time: Double, ms: Int? = nil, value: Int = 16) -> DecisionDraft {
        DecisionDraft(handNumber: 1, cell: TrainingCell(handType: .hard, playerValue: value, dealerUpcard: 10),
                      chosen: .action(correct ? .hit : .stand), correctAction: .hit,
                      isCorrect: correct, responseMs: ms, decidedAt: t(time))
    }

    func draft(_ module: TrainingModule = .strategy, start: Double = 100,
               decisions: [DecisionDraft] = [], checks: [CountCheckDraft] = []) -> SessionDraft {
        SessionDraft(module: module, mode: "test", startedAt: t(start), endedAt: t(start + 60),
                     rules: RulePreset.downtownVegas.rules, decisions: decisions, countChecks: checks)
    }

    @Test("RecordedChoice round-trips actions and timeout")
    func recordedChoice() {
        #expect(RecordedChoice.timeout.rawValue == "timeout")
        #expect(RecordedChoice(rawValue: "timeout") == .timeout)
        #expect(RecordedChoice(rawValue: "double") == .action(.double))
        #expect(RecordedChoice(rawValue: "fold") == nil)
    }

    @Test("Saving stores the cached summary, rules snapshot and records")
    func saveSummary() throws {
        let d = draft(decisions: [decision(true, at: 101, ms: 1000), decision(true, at: 102, ms: 2000),
                                  decision(false, at: 103)],
                      checks: [CountCheckDraft(kind: .runningCount, expected: 2, answered: 2, isCorrect: true,
                                               responseMs: nil, cardsSeen: 10, checkedAt: t(104))])
        try store.save(d)

        let session = try #require(try context.fetch(FetchDescriptor<Session>()).first)
        #expect(session.id == d.id)
        #expect(session.module == "strategy")
        #expect(session.decisionCount == 3)
        #expect(session.correctDecisions == 2)
        #expect(session.countCheckCount == 1)
        #expect(session.correctCountChecks == 1)
        #expect(session.bestStreak == 2)
        #expect(session.meanResponseMs == 1500)
        #expect(try JSONDecoder().decode(BlackjackRules.self, from: session.rulesJSON)
                == RulePreset.downtownVegas.rules)
        #expect(session.decisions.map { $0.sequence }.sorted() == [0, 1, 2])
        #expect(session.decisions.first { $0.sequence == 2 }?.chosenAction == "stand")
    }

    @Test("Timeouts are stored as 'timeout'")
    func timeoutStored() throws {
        var d = decision(false, at: 101)
        d.chosen = .timeout
        try store.save(draft(decisions: [d]))
        #expect(try context.fetch(FetchDescriptor<DecisionRecord>()).first?.chosenAction == "timeout")
    }

    @Test("Session samples come back oldest first")
    func sessionOrder() throws {
        try store.save(draft(.countingRC, start: 500))
        try store.save(draft(.strategy, start: 100))
        #expect(try store.sessionSamples().map(\.module) == [.strategy, .countingRC])
    }

    @Test("Decisions are chronological, ties broken by sequence")
    func decisionOrder() throws {
        // Three decisions share one timestamp; only sequence orders them.
        try store.save(draft(start: 200, decisions: [decision(true, at: 300, value: 12),
                                                     decision(false, at: 300, value: 13),
                                                     decision(true, at: 300, value: 14)]))
        try store.save(draft(start: 100, decisions: [decision(true, at: 150, value: 5)]))
        #expect(try store.decisionSamples().map(\.cell.playerValue) == [5, 12, 13, 14])
    }

    @Test("Module filter applies to decisions and count checks")
    func moduleFilter() throws {
        let check = CountCheckDraft(kind: .trueCount, expected: 1.5, answered: 1.5, isCorrect: true,
                                    responseMs: 700, cardsSeen: 52, checkedAt: t(120))
        try store.save(draft(.strategy, decisions: [decision(true, at: 110)]))
        try store.save(draft(.shoe, start: 200, decisions: [decision(false, at: 210)], checks: [check]))
        try store.save(draft(.countingTC, start: 300, checks: [check]))
        #expect(try store.decisionSamples().count == 2)
        #expect(try store.decisionSamples(modules: [.strategy]).map(\.isCorrect) == [true])
        #expect(try store.countSamples().count == 2)
        #expect(try store.countSamples(modules: [.countingTC]).count == 1)
    }

    @Test("Rows with unknown raw values are skipped")
    func unknownRowsSkipped() throws {
        try store.save(draft(decisions: [decision(true, at: 101)]))
        let bogus = DecisionRecord(sequence: 9, decidedAt: t(102), handNumber: 1, handType: "weird",
                                   playerValue: 1, dealerUpcard: 1, chosenAction: "hit",
                                   correctAction: "hit", isCorrect: true, responseMs: nil)
        let session = try #require(try context.fetch(FetchDescriptor<Session>()).first)
        session.decisions.append(bogus)
        try context.save()
        #expect(try store.decisionSamples().count == 1)
    }

    @Test("deleteAll removes every session and record and bumps revision")
    func deleteAll() throws {
        try store.save(draft(decisions: [decision(true, at: 101)]))
        let before = store.revision
        try store.deleteAll()
        #expect(store.revision == before + 1)
        #expect(try store.sessionSamples().isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 0)
    }

    @Test("save bumps revision")
    func saveRevision() throws {
        let before = store.revision
        try store.save(draft())
        #expect(store.revision == before + 1)
    }

    @Test("Saving two drafts with the same id leaves exactly one Session row (SwiftData upserts on .unique)")
    func duplicateIdUpserts() throws {
        let d1 = draft(decisions: [decision(true, at: 101)])
        try store.save(d1)
        var d2 = draft(start: 200, decisions: [decision(false, at: 201)])
        d2.id = d1.id
        try store.save(d2)
        #expect(try context.fetchCount(FetchDescriptor<Session>()) == 1)
    }

    @Test("isStorageDegraded defaults to false, and is true when passed")
    func storageDegradedFlag() throws {
        #expect(store.isStorageDegraded == false)
        let degradedContainer = try BJSModelContainer.make(inMemory: true)
        let degradedStore = SessionStore(context: degradedContainer.mainContext, isStorageDegraded: true)
        #expect(degradedStore.isStorageDegraded == true)
    }

    func draft(mode: String?, decisions: [DecisionDraft]) -> SessionDraft {
        SessionDraft(module: .strategy, mode: mode, startedAt: t(100), endedAt: t(160),
                     rules: RulePreset.downtownVegas.rules, decisions: decisions)
    }

    @Test("Stats queries drop Learn sessions; forStats: false keeps them")
    func learnExcludedFromStats() throws {
        try store.save(draft(mode: "learn", decisions: [decision(true, at: 101)]))
        try store.save(draft(mode: "test", decisions: [decision(false, at: 102)]))

        #expect(try store.sessionSamples().count == 1)
        #expect(try store.sessionSamples(forStats: false).count == 2)
        #expect(try store.decisionSamples().map { $0.isCorrect } == [false])
        #expect(try store.decisionSamples(forStats: false).count == 2)
        #expect(try store.decisionSamples(modules: [.strategy]).count == 1)
    }

    @Test("Sessions with no mode count towards stats")
    func nilModeCounts() throws {
        try store.save(draft(mode: nil, decisions: [decision(true, at: 101)]))
        #expect(try store.decisionSamples().count == 1)
    }

    @Test("countSamples(forStats:) drops Learn sessions only when asked for stats")
    func countSamplesForStats() throws {
        let learnCheck = CountCheckDraft(kind: .runningCount, expected: 1, answered: 1, isCorrect: true,
                                         responseMs: 900, cardsSeen: 10, checkedAt: t(101))
        try store.save(SessionDraft(module: .strategy, mode: "learn", startedAt: t(100), endedAt: t(160),
                                    rules: BlackjackRules(), countChecks: [learnCheck]))
        let tcCheck = CountCheckDraft(kind: .trueCount, expected: 2, answered: 2, isCorrect: true,
                                      responseMs: 1200, cardsSeen: 104, checkedAt: t(201))
        try store.save(SessionDraft(module: .countingTC, mode: "exact", startedAt: t(200), endedAt: t(260),
                                    rules: BlackjackRules(), countChecks: [tcCheck]))

        #expect(try store.countSamples().map(\.kind) == [.trueCount])
        #expect(try store.countSamples(forStats: false).map(\.kind) == [.runningCount, .trueCount])
        #expect(try store.countSamples(modules: [.countingTC]).count == 1)
        #expect(try store.countSamples(modules: [.countingRC]).isEmpty)
    }

    @Test("History lists every session newest first, Learn included, with its mode")
    func historyEntries() throws {
        var learn = draft(start: 300)
        learn.mode = "learn"
        try store.save(draft(start: 100))
        try store.save(learn)
        try store.save(draft(.countingRC, start: 200))
        let entries = try store.historyEntries()
        #expect(entries.map(\.sample.startedAt) == [t(300), t(200), t(100)])
        #expect(entries.map(\.mode) == ["learn", "test", "test"])
        #expect(entries.map(\.sample.module) == [.strategy, .countingRC, .strategy])
    }

    @Test("since filters sessions and decisions by date")
    func sinceFilter() throws {
        try store.save(draft(start: 100, decisions: [decision(true, at: 101)]))
        try store.save(draft(start: 500, decisions: [decision(false, at: 501)]))
        #expect(try store.sessionSamples(since: t(400)).map(\.startedAt) == [t(500)])
        #expect(try store.decisionSamples(since: t(400)).map(\.isCorrect) == [false])
        #expect(try store.sessionSamples().count == 2)
        #expect(try store.decisionSamples().count == 2)
    }

    @Test("sessionDetail returns one session's records in order")
    func sessionDetail() throws {
        let d = draft(start: 100,
                      decisions: [decision(true, at: 101, ms: 900), decision(false, at: 102)],
                      checks: [CountCheckDraft(kind: .trueCount, expected: 2.8, answered: 3, isCorrect: true,
                                               responseMs: 400, cardsSeen: 104, checkedAt: t(103))])
        try store.save(d)
        try store.save(draft(start: 200, decisions: [decision(true, at: 201)]))

        let detail = try #require(try store.sessionDetail(id: d.id))
        #expect(detail.sample.id == d.id)
        #expect(detail.mode == "test")
        #expect(detail.rules == RulePreset.downtownVegas.rules)
        #expect(detail.bestStreak == 1)
        #expect(detail.decisions.map(\.isCorrect) == [true, false])
        #expect(detail.decisions[0].responseMs == 900)
        #expect(detail.decisions[1].chosen == .action(.stand))
        #expect(detail.decisions[1].correctAction == .hit)
        #expect(detail.decisions[1].cell == TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10))
        #expect(detail.checks.map(\.cardsSeen) == [104])
        #expect(detail.checks[0].sample.expected == 2.8)
        #expect(detail.checks[0].sample.kind == .trueCount)
    }

    @Test("sessionDetail is nil for an unknown id")
    func sessionDetailMissing() throws {
        try store.save(draft())
        #expect(try store.sessionDetail(id: UUID()) == nil)
    }

    @Test("sessionDetail omits a decision whose cell is outside WhyContext's safe range")
    func sessionDetailDropsOutOfRangeCell() throws {
        let d = draft(start: 100, decisions: [decision(true, at: 101)])
        try store.save(d)
        let session = try #require(try context.fetch(FetchDescriptor<Session>()).first)
        // A pair playerValue of 12 is outside the valid pair range (2...11): WhyContext(cell:)
        // would otherwise misinterpret it as a queen pair.
        let bogus = DecisionRecord(sequence: 9, decidedAt: t(102), handNumber: 1, handType: "pair",
                                   playerValue: 12, dealerUpcard: 10, chosenAction: "hit",
                                   correctAction: "hit", isCorrect: true, responseMs: nil)
        session.decisions.append(bogus)
        try context.save()

        let detail = try #require(try store.sessionDetail(id: d.id))
        #expect(detail.decisions.count == 1)
        #expect(detail.decisions[0].isCorrect == true)
    }
}
