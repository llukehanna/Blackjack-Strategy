import Foundation

/// The Progress tab's time window (Step 6 spec §1). An N-day window is today plus the previous
/// N − 1 calendar days, so a per-day trend chart shows exactly N days.
public enum ProgressRange: String, CaseIterable, Sendable {
    case week
    case month
    case allTime

    /// Calendar days covered; nil for all time.
    public var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .allTime: return nil
        }
    }

    /// The start of the window, or nil for all time.
    public func since(now: Date, calendar: Calendar) -> Date? {
        guard let days else { return nil }
        return calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now))
    }
}
