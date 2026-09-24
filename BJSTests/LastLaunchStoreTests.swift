import BJSCore
import Foundation
import Testing
@testable import BJS

@MainActor
@Suite("LastLaunchStore")
struct LastLaunchStoreTests {

    private let config = StrategySessionConfig(mode: .speed, length: .hands50, filter: .soft)

    @Test("First launch: nothing to continue")
    func fresh() {
        #expect(LastLaunchStore(defaults: TestDefaults.make()).lastLaunch == nil)
    }

    @Test("A recorded launch persists across store instances")
    func persists() {
        let defaults = TestDefaults.make()
        LastLaunchStore(defaults: defaults).record(.forStrategy(config))
        let reloaded = LastLaunchStore(defaults: defaults).lastLaunch
        #expect(reloaded == LastLaunch(module: .strategy, mode: "speed", strategy: config))
    }

    @Test("Stored as JSON Data under 'lastLaunch' with module, mode and setup")
    func storageFormat() throws {
        let defaults = TestDefaults.make()
        LastLaunchStore(defaults: defaults).record(.forStrategy(config))
        let data = try #require(defaults.data(forKey: "lastLaunch"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["module"] as? String == "strategy")
        #expect(json["mode"] as? String == "speed")
        #expect(json["strategy"] != nil)
        #expect(try LastLaunch.decode(data).strategy == config)
    }

    @Test("Corrupt JSON hides Continue instead of crashing")
    func corrupt() {
        let defaults = TestDefaults.make()
        defaults.set(Data("nope".utf8), forKey: "lastLaunch")
        #expect(LastLaunchStore(defaults: defaults).lastLaunch == nil)
    }
}

@Suite("Training display text")
struct TrainingDisplayTests {

    @Test("Setup picker titles")
    func pickerTitles() {
        #expect(StrategyMode.allCases.map(\.displayName) == ["Learn", "Test", "Speed", "Weak spots"])
        #expect(StrategySessionLength.allCases.map(\.displayName) == ["25", "50", "100", "Endless"])
        #expect(HandFilter.allCases.map(\.displayName) == ["All", "Hard", "Soft", "Pairs"])
        #expect(StrategyMode.allCases.allSatisfy { !$0.setupDescription.isEmpty })
    }

    @Test("Continue button text")
    func continueText() {
        let launch = LastLaunch.forStrategy(StrategySessionConfig(mode: .weakSpots, length: .endless, filter: .pairs))
        #expect(LastLaunchText.title(launch) == "Continue: Strategy · Weak spots")
        #expect(LastLaunchText.detail(launch) == "Endless · Pairs")
        let plain = LastLaunch(module: .countingRC, mode: nil, strategy: nil)
        #expect(LastLaunchText.title(plain) == "Continue: Running count")
        #expect(LastLaunchText.detail(plain) == nil)
    }
}

@Suite("LaunchConfiguration seed")
struct LaunchSeedTests {

    @Test("A Strategy seed is read only when it is a valid UInt64")
    func strategySeed() {
        #expect(LaunchConfiguration(environment: [:]).strategySeed == nil)
        #expect(LaunchConfiguration(environment: ["BJS_STRATEGY_SEED": "42"]).strategySeed == 42)
        #expect(LaunchConfiguration(environment: ["BJS_STRATEGY_SEED": "-1"]).strategySeed == nil)
    }
}
