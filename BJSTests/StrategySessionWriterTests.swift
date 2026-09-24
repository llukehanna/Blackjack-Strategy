import BJSCore
import Foundation
import SwiftData
import Testing
@testable import BJS

/// Every test creates its in-memory container before creating any model object.
@MainActor
@Suite("Strategy session writer", .serialized)
struct StrategySessionWriterTests {

    private let decisions = [
        StrategyFixtures.decision(1, choice: .action(.hit), responseMs: 800),
        StrategyFixtures.decision(2, choice: .action(.stand), responseMs: 1_200),
        StrategyFixtures.decision(3, choice: .timeout, responseMs: 3_000),
        StrategyFixtures.decision(4, choice: .action(.hit), responseMs: 1_000),
    ]

    @Test("Saving writes one strategy Session with its mode, rules and cached summary")
    func session() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let snapshot = StrategyFixtures.snapshot(decisions, mode: .speed)
        try SwiftDataStrategySessionSaver(context: context).save(snapshot)

        let sessions = try context.fetch(FetchDescriptor<Session>())
        let session = try #require(sessions.first)
        #expect(sessions.count == 1)
        #expect(session.id == snapshot.id)
        #expect(session.module == "strategy")
        #expect(session.mode == "speed")
        #expect(session.startedAt == snapshot.startedAt)
        #expect(session.endedAt == snapshot.endedAt)
        #expect(try RulesCoding.decode(session.rulesJSON) == BlackjackRules())
        #expect(session.decisionCount == 4)
        #expect(session.correctDecisions == 2)
        #expect(session.countChecks == 0)
        #expect(session.bestStreak == 1)
        #expect(session.meanResponseMs == 1_500)
        #expect(session.decisions.count == 4)
    }

    @Test("Each decision keeps its own decidedAt; a timeout is stored as \"timeout\"")
    func records() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        try SwiftDataStrategySessionSaver(context: context).save(StrategyFixtures.snapshot(decisions))

        let records = try context.fetch(FetchDescriptor<DecisionRecord>(sortBy: [SortDescriptor(\.decidedAt)]))
        #expect(records.map(\.decidedAt) == decisions.map(\.decidedAt))
        #expect(records.map(\.chosenAction) == ["hit", "stand", "timeout", "hit"])
        #expect(records.map(\.isCorrect) == [true, false, false, true])
        #expect(records.allSatisfy { $0.correctAction == "hit" && $0.handType == "hard" })
        #expect(records.allSatisfy { $0.playerValue == 16 && $0.dealerUpcard == 7 })
        #expect(records.map(\.responseMs) == [800, 1_200, 3_000, 1_000])
        #expect(records.map(\.handNumber) == [1, 2, 3, 4])
    }

    @Test("Saved decisions map back to the same cells and give the hub its streak")
    func mapsBack() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        try SwiftDataStrategySessionSaver(context: context).save(StrategyFixtures.snapshot(decisions))

        let samples = DecisionHistory.recentSamples(in: context)
        #expect(samples.count == 4)
        #expect(Set(samples.map(\.cell)) == [TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 7)])
        #expect(ProgressStats.currentStreak(samples) == 1)          // newest (4) correct, then the timeout
    }

    @Test("Decision history returns only the newest 500 decisions")
    func historyWindow() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        for index in 0..<510 {
            context.insert(DecisionRecord(handNumber: index, handType: "hard", playerValue: 12, dealerUpcard: 2,
                                          chosenAction: "hit", correctAction: "stand", isCorrect: false,
                                          responseMs: nil,
                                          decidedAt: StrategyFixtures.start.addingTimeInterval(TimeInterval(index))))
        }
        try context.save()

        let samples = DecisionHistory.recentSamples(in: context)
        #expect(samples.count == 500)
        #expect(samples.map(\.date).min() == StrategyFixtures.start.addingTimeInterval(10))
    }
}
