import BJSCore
import Foundation
import SwiftData
import Testing
@testable import BJS

/// Every test creates its in-memory container before creating any model object
/// (SwiftData needs a loaded container for a model type before instances exist).
@MainActor
@Suite("Persistence (SchemaV1)", .serialized)
struct PersistenceTests {

    private static let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func makeSession(module: TrainingModule = .strategy) -> Session {
        Session(module: module.rawValue, mode: "test", startedAt: Self.start,
                endedAt: Self.start.addingTimeInterval(600), rulesJSON: RulesCoding.encode(BlackjackRules()),
                decisionCount: 2, correctDecisions: 1, countChecks: 1, correctCountChecks: 1,
                bestStreak: 1, meanResponseMs: 950)
    }

    private func makeDecision(secondsAfterStart: TimeInterval, isCorrect: Bool = true) -> DecisionRecord {
        DecisionRecord(handNumber: 1, handType: "soft", playerValue: 18, dealerUpcard: 11,
                       chosenAction: "stand", correctAction: "hit", isCorrect: isCorrect, responseMs: 1200,
                       decidedAt: Self.start.addingTimeInterval(secondsAfterStart))
    }

    private func makeCountCheck(secondsAfterStart: TimeInterval) -> CountCheckRecord {
        CountCheckRecord(kind: "true", expected: 2.5, answered: 2.0, isCorrect: false, responseMs: 3000,
                         cardsSeen: 104, answeredAt: Self.start.addingTimeInterval(secondsAfterStart))
    }

    @Test("Schema is version 1.0.0 with three models and no migration stages")
    func schemaShape() {
        #expect(SchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(SchemaV1.models.count == 3)
        #expect(BJSMigrationPlan.schemas.count == 1)
        #expect(BJSMigrationPlan.stages.isEmpty)
    }

    @Test("A session with records saves and fetches back")
    func roundTrip() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.decisions.append(makeDecision(secondsAfterStart: 10))
        session.decisions.append(makeDecision(secondsAfterStart: 20, isCorrect: false))
        session.countCheckRecords.append(makeCountCheck(secondsAfterStart: 30))
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<Session>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.decisions.count == 2)
        #expect(sessions.first?.countCheckRecords.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 2)
        let rules = try RulesCoding.decode(try #require(sessions.first).rulesJSON)
        #expect(rules == BlackjackRules())
    }

    @Test("Deleting a session cascades to its records")
    func cascade() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.decisions.append(makeDecision(secondsAfterStart: 10))
        session.countCheckRecords.append(makeCountCheck(secondsAfterStart: 20))
        try context.save()

        context.delete(session)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Session>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 0)
    }

    @Test("Reset progress deletes every session and record")
    func reset() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        for module in [TrainingModule.strategy, .countingRC, .shoe] {
            let session = makeSession(module: module)
            context.insert(session)
            session.decisions.append(makeDecision(secondsAfterStart: 10))
            session.countCheckRecords.append(makeCountCheck(secondsAfterStart: 20))
        }
        context.insert(makeDecision(secondsAfterStart: 99))   // orphan
        try context.save()

        try ProgressReset.deleteAllProgress(in: context)

        #expect(try context.fetchCount(FetchDescriptor<Session>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 0)
    }

    @Test("Decision mapper uses the record's own decidedAt, not the session start")
    func decisionMapper() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let record = makeDecision(secondsAfterStart: 42, isCorrect: false)
        container.mainContext.insert(record)
        let sample = try #require(ProgressMapper.decisionSample(record))
        #expect(sample.date == Self.start.addingTimeInterval(42))
        #expect(sample.cell == TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 11))
        #expect(sample.isCorrect == false)
        #expect(sample.responseMs == 1200)
    }

    @Test("Decisions in one session keep their order through the mapper")
    func decisionOrder() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.decisions.append(makeDecision(secondsAfterStart: 10, isCorrect: false))
        session.decisions.append(makeDecision(secondsAfterStart: 20))
        session.decisions.append(makeDecision(secondsAfterStart: 30))
        try context.save()

        let samples = ProgressMapper.decisionSamples(try context.fetch(FetchDescriptor<DecisionRecord>()))
        // Streak counts back from the newest: two correct, then the miss.
        #expect(ProgressStats.currentStreak(samples) == 2)
    }

    @Test("Count mapper uses answeredAt and the kind raw value")
    func countMapper() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let record = makeCountCheck(secondsAfterStart: 7)
        container.mainContext.insert(record)
        let sample = try #require(ProgressMapper.countSample(record))
        #expect(sample.date == Self.start.addingTimeInterval(7))
        #expect(sample.kind == .trueCount)
        #expect(sample.expected == 2.5)
        #expect(sample.answered == 2.0)
        #expect(!sample.isCorrect)
        #expect(sample.responseMs == 3000)
    }

    @Test("Session mapper copies the cached summary")
    func sessionMapper() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let session = makeSession(module: .countingTC)
        container.mainContext.insert(session)
        let sample = try #require(ProgressMapper.sessionSample(session))
        #expect(sample.id == session.id)
        #expect(sample.module == .countingTC)
        #expect(sample.startedAt == Self.start)
        #expect(sample.decisionCount == 2)
        #expect(sample.correctDecisions == 1)
        #expect(sample.countChecks == 1)
        #expect(sample.correctCountChecks == 1)
    }

    @Test("Unknown enum strings are skipped, not crashed on")
    func unknownStrings() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.module = "poker"
        #expect(ProgressMapper.sessionSample(session) == nil)

        let decision = makeDecision(secondsAfterStart: 1)
        context.insert(decision)
        decision.handType = "weird"
        #expect(ProgressMapper.decisionSample(decision) == nil)

        let check = makeCountCheck(secondsAfterStart: 1)
        context.insert(check)
        check.kind = "sideways"
        #expect(ProgressMapper.countSample(check) == nil)
    }
}
