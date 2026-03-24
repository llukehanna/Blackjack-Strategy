import Testing
import SwiftData
import Foundation
@testable import BJS
import BJSCore

@MainActor
struct PersistenceTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: TrainingSession.self, SessionDecision.self,
            configurations: config
        )
    }

    @Test func sessionCanBeSavedAndFetched() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let rules = BlackjackRules()
        let rulesData = try JSONEncoder().encode(rules)
        let session = TrainingSession(mode: "test", rulesJSON: rulesData)
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TrainingSession>())
        #expect(fetched.count == 1)
        #expect(fetched[0].mode == "test")
    }

    @Test func decisionsLinkedToSession() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let rules = BlackjackRules()
        let rulesData = try JSONEncoder().encode(rules)
        let session = TrainingSession(mode: "learn", rulesJSON: rulesData)
        context.insert(session)

        let decision = SessionDecision(
            handDescription: "Hard 16 vs 10",
            playerAction: "stand",
            correctAction: "hit",
            isCorrect: false,
            handNumber: 1
        )
        decision.session = session
        context.insert(decision)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TrainingSession>())
        #expect(fetched[0].decisions.count == 1)
        #expect(fetched[0].decisions[0].handDescription == "Hard 16 vs 10")
        #expect(fetched[0].decisions[0].isCorrect == false)
    }

    @Test func sessionComputedProperties() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let rules = BlackjackRules()
        let rulesData = try JSONEncoder().encode(rules)
        let session = TrainingSession(mode: "test", rulesJSON: rulesData)
        context.insert(session)

        // Add 3 correct, 1 incorrect
        for i in 1...4 {
            let decision = SessionDecision(
                handDescription: "Hand \(i)",
                playerAction: "hit",
                correctAction: "hit",
                isCorrect: i <= 3,
                handNumber: i
            )
            decision.session = session
            context.insert(decision)
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TrainingSession>())
        let s = fetched[0]
        #expect(s.totalDecisions == 4)
        #expect(s.correctDecisions == 3)
        #expect(s.accuracyPercentage == 75.0)
        #expect(s.errorCount == 1)
        #expect(s.bestStreak == 3)
    }

    @Test func rulesJSONRoundTrips() throws {
        var rules = BlackjackRules()
        rules.deckCount = .two
        rules.dealerSoft17 = .hits
        let data = try JSONEncoder().encode(rules)
        let decoded = try JSONDecoder().decode(BlackjackRules.self, from: data)
        #expect(decoded.deckCount == .two)
        #expect(decoded.dealerSoft17 == .hits)
    }
}
