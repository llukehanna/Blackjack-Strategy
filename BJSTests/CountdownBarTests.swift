import Foundation
import Testing
@testable import BJS

@Suite("CountdownBar")
struct CountdownBarTests {

    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test("Remaining fraction runs from 1 to 0 and is clamped")
    func remaining() {
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start, duration: 3) == 1)
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start.addingTimeInterval(1.5), duration: 3) == 0.5)
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start.addingTimeInterval(5), duration: 3) == 0)
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start.addingTimeInterval(-1), duration: 3) == 1)
        #expect(CountdownBar.remainingFraction(startedAt: start, now: start, duration: 0) == 0)
    }
}
