import Foundation
import SwiftData
import Testing
import BJSCore
@testable import BJS

@MainActor
struct SchemaTests {

    func makeSession(module: String = "strategy") -> Session {
        Session(id: UUID(), module: module, mode: "test",
                startedAt: Date(timeIntervalSince1970: 1_000), endedAt: Date(timeIntervalSince1970: 2_000),
                rulesJSON: Data("{}".utf8), decisionCount: 1, correctDecisions: 1,
                countCheckCount: 1, correctCountChecks: 0, bestStreak: 1, meanResponseMs: 800)
    }

    func makeDecision(handType: String = "soft", sequence: Int = 0) -> DecisionRecord {
        DecisionRecord(sequence: sequence, decidedAt: Date(timeIntervalSince1970: 1_500), handNumber: 1,
                       handType: handType, playerValue: 18, dealerUpcard: 9,
                       chosenAction: "stand", correctAction: "hit", isCorrect: false, responseMs: 900)
    }

    func makeCheck(kind: String = "running") -> CountCheckRecord {
        CountCheckRecord(sequence: 0, checkedAt: Date(timeIntervalSince1970: 1_600), kind: kind,
                         expected: 3, answered: 2, isCorrect: false, responseMs: 1200, cardsSeen: 26)
    }

    @Test("Container saves a session with records; deleting it cascades")
    func cascade() throws {
        let container = try BJSModelContainer.make(inMemory: true)
        let context = container.mainContext
        let session = makeSession()
        context.insert(session)
        session.decisions.append(makeDecision())
        session.countChecks.append(makeCheck())
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 1)

        context.delete(session)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Session>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DecisionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CountCheckRecord>()) == 0)
    }

    @Test("Records map to BJSCore samples")
    func mappers() throws {
        let session = makeSession()
        #expect(session.sample == SessionSample(id: session.id, module: .strategy,
                                                startedAt: Date(timeIntervalSince1970: 1_000),
                                                decisionCount: 1, correctDecisions: 1,
                                                countChecks: 1, correctCountChecks: 0))
        #expect(makeDecision().sample == DecisionSample(
            date: Date(timeIntervalSince1970: 1_500),
            cell: TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9),
            isCorrect: false, responseMs: 900))
        #expect(makeCheck().sample == CountSample(date: Date(timeIntervalSince1970: 1_600), kind: .runningCount,
                                                  expected: 3, answered: 2, isCorrect: false, responseMs: 1200))
    }

    @Test("Unknown raw values map to nil instead of crashing")
    func unknownRawValues() {
        #expect(makeSession(module: "poker").sample == nil)
        #expect(makeDecision(handType: "weird").sample == nil)
        #expect(makeCheck(kind: "sideways").sample == nil)
    }
}
