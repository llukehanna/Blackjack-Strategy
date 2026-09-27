import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct CountingSetupTests {

    @Test("RC setup defaults (Step 4 spec §4)")
    func runningDefaults() {
        let s = RunningCountSetup()
        #expect(s.groupSize == 1)
        #expect(s.pace == 1.0)
        #expect(s.length == .cards(52))
        #expect(!s.randomCheckpoints)
        #expect(RunningCountSetup.groupSizes == [1, 2, 3])
        #expect(RunningCountLength.options == [.cards(10), .cards(26), .cards(52), .fullShoe])
        #expect(RunningCountLength.options.map(\.title) == ["10", "26", "52", "Shoe"])
        #expect(RunningCountLength.fullShoe.drillLength == .fullShoe)
        #expect(RunningCountLength.cards(26).drillLength == .cards(26))
    }

    @Test("Pace moves in tenths and clamps to 0.3–2.0 s")
    func paceTenths() {
        var s = RunningCountSetup()
        #expect(s.paceTenths == 10)
        s.paceTenths = 3
        #expect(s.pace == 0.3)
        s.paceTenths = 1
        #expect(s.pace == 0.3)
        s.paceTenths = 25
        #expect(s.pace == 2.0)
        #expect(RunningCountSetup.paceTenthsRange == 3...20)
    }

    @Test("TC setup defaults and lengths")
    func trueDefaults() {
        #expect(TrueCountSetup().length == .questions(10))
        #expect(TrueCountLength.options == [.questions(10), .questions(20), .endless])
        #expect(TrueCountLength.options.map(\.title) == ["10", "20", "∞"])
        #expect(TrueCountLength.questions(20).questionLimit == 20)
        #expect(TrueCountLength.endless.questionLimit == nil)
    }

    @Test("lastLaunch records the drill's training module and round-trips the setup")
    func lastLaunchRoundTrip() throws {
        var rc = RunningCountSetup()
        rc.groupSize = 3
        rc.randomCheckpoints = true
        let rcLaunch = try CountingSetup.runningCount(rc).lastLaunch()
        #expect(rcLaunch.module == .countingRC)
        #expect(rcLaunch.mode == nil)
        #expect(CountingSetup.decode(rcLaunch.setup) == .runningCount(rc))

        let tcLaunch = try CountingSetup.trueCount(TrueCountSetup(length: .endless)).lastLaunch()
        #expect(tcLaunch.module == .countingTC)
        #expect(tcLaunch.mode == nil)
        #expect(CountingSetup.decode(tcLaunch.setup) == .trueCount(TrueCountSetup(length: .endless)))
    }

    @Test("Undecodable setup data gives nil, so Continue falls back to the menu")
    func decodeFailure() {
        #expect(CountingSetup.decode(Data("nope".utf8)) == nil)
    }
}
