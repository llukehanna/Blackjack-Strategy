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

    @Test("Moments a minute apart either side of midnight land in different windows")
    func midnightBoundary() {
        let lateDay99 = Date(timeIntervalSince1970: 99 * 86_400 + 23 * 3_600 + 59 * 60)
        let earlyDay100 = Date(timeIntervalSince1970: 100 * 86_400 + 60)
        let sinceLate = ProgressRange.week.since(now: lateDay99, calendar: utc)
        let sinceEarly = ProgressRange.week.since(now: earlyDay100, calendar: utc)
        #expect(sinceLate != sinceEarly)
        #expect(sinceLate == day(93))
        #expect(sinceEarly == day(94))
    }

    @Test("A week window in a DST-observing zone lands on local midnight, not a fixed 7×86,400s offset")
    func springForwardDST() throws {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        // 2026-03-08 is the US spring-forward Sunday; this `now` is two days after it.
        let now = try #require(newYork.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12)))
        let expected = try #require(newYork.date(from: DateComponents(year: 2026, month: 3, day: 4)))
        #expect(ProgressRange.week.since(now: now, calendar: newYork) == expected)
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
