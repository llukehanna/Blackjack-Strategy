import Foundation
import Testing
@testable import BJSCore

struct ProgressRangeTests {

    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    func day(_ n: Double, hour: Double = 0) -> Date { Date(timeIntervalSince1970: n * 86_400 + hour * 3_600) }

    @Test("An N-day window is today plus the previous N − 1 calendar days")
    func calendarDays() {
        #expect(ProgressRange.week.since(now: day(100, hour: 23.9), calendar: utc) == day(94))
        #expect(ProgressRange.week.since(now: day(100, hour: 0.01), calendar: utc) == day(94))
        #expect(ProgressRange.month.since(now: day(100, hour: 12), calendar: utc) == day(71))
    }

    @Test("All time has no start")
    func allTime() {
        #expect(ProgressRange.allTime.since(now: day(100), calendar: utc) == nil)
        #expect(ProgressRange.allTime.days == nil)
        #expect(ProgressRange.week.days == 7)
        #expect(ProgressRange.month.days == 30)
    }

    @Test("Ranges are listed short to long")
    func order() {
        #expect(ProgressRange.allCases == [.week, .month, .allTime])
    }
}
