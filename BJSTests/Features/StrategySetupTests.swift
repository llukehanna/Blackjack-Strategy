import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct StrategySetupTests {

    @Test("Defaults: Test mode, 25 hands, all hands")
    func defaults() {
        let s = StrategySetup()
        #expect(s.mode == .test)
        #expect(s.length == .hands(25))
        #expect(s.filter == .all)
    }

    @Test("Length options and hand limits")
    func lengths() {
        #expect(StrategyLength.options == [.hands(25), .hands(50), .hands(100), .endless])
        #expect(StrategyLength.options.map { $0.title } == ["25", "50", "100", "∞"])
        #expect(StrategyLength.hands(50).handLimit == 50)
        #expect(StrategyLength.endless.handLimit == nil)
    }

    @Test("Mode behaviour flags")
    func modes() {
        #expect(StrategyMode.allCases.map { $0.title } == ["Learn", "Test", "Speed", "Weak"])
        #expect(StrategyMode.learn.showsHint && !StrategyMode.test.showsHint)
        #expect(StrategyMode.speed.isTimed && !StrategyMode.weakSpots.isTimed)
        #expect(StrategyMode.weakSpots.usesWeights && !StrategyMode.test.usesWeights)
        #expect(StrategyMode.learn.rawValue == "learn")
    }

    @Test("Learn is the mode SessionStore excludes from stats")
    func learnExcluded() {
        #expect(SessionStore.statsExcludedModes == [StrategyMode.learn.rawValue])
    }

    @Test("lastLaunch round-trips the setup")
    func lastLaunchRoundTrip() throws {
        let setup = StrategySetup(mode: .speed, length: .endless, filter: .pairs)
        let launch = try setup.lastLaunch()
        #expect(launch.module == .strategy)
        #expect(launch.mode == "speed")
        #expect(StrategySetup.decode(launch.setup) == setup)
    }

    @Test("Undecodable setup data returns nil")
    func badData() {
        #expect(StrategySetup.decode(Data("x".utf8)) == nil)
    }

    @Test("Filter titles")
    func filterTitles() {
        #expect(HandFilter.allCases.map { $0.title } == ["All", "Hard", "Soft", "Pairs"])
    }
}
