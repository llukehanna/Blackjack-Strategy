import Foundation
import BJSCore

/// Copy for the Progress tab and session detail (Step 6 spec §2, §3).
enum ProgressText {
    static let noPointsCaption = "No sessions in this range"
    static let noHeatCaption = "No strategy decisions in this range"
    static let loadFailed = "Couldn't load your progress"
    static let emptyTitle = "No sessions yet"
    static let emptyMessage = "Finish a training session and your accuracy, trends and weak spots show up here."
    static let emptyButton = "Start training"

    static func rangeTitle(_ range: ProgressRange) -> String {
        switch range {
        case .week: return "7 days"
        case .month: return "30 days"
        case .allTime: return "All time"
        }
    }

    static func moduleTitle(_ module: TrainingModule) -> String {
        switch module {
        case .strategy: return "Strategy"
        case .countingRC: return "Running count"
        case .countingTC: return "True count"
        case .shoe: return "Shoe Sim"
        }
    }

    /// For the trend picker, where four segments share the width.
    static func moduleShortTitle(_ module: TrainingModule) -> String {
        switch module {
        case .strategy: return "Strategy"
        case .countingRC: return "Running"
        case .countingTC: return "True"
        case .shoe: return "Shoe"
        }
    }

    static func handTypeTitle(_ type: HandType) -> String {
        switch type {
        case .hard: return "Hard"
        case .soft: return "Soft"
        case .pair: return "Pairs"
        }
    }

    /// The saved mode's display name, or nil when there's none to show. Strategy modes are
    /// `StrategyMode` raw values (learn | test | speed | weakSpots); TC modes are
    /// `TrueCountConvention` raw values.
    static func modeTitle(_ mode: String?, module: TrainingModule) -> String? {
        guard let mode else { return nil }
        if module == .countingTC {
            switch TrueCountConvention(rawValue: mode) {
            case .exact: return "Exact"
            case .floor: return "Floor"
            case .truncate: return "Truncate"
            case nil: return nil
            }
        }
        switch mode {
        case "learn": return "Learn"
        case "test": return "Test"
        case "speed": return "Speed"
        case "weakSpots": return "Weak spots"
        default: return nil
        }
    }

    /// "Strategy · Test", "Running count", "True count · Exact".
    static func sessionTitle(module: TrainingModule, mode: String?) -> String {
        guard let modeTitle = modeTitle(mode, module: module) else { return moduleTitle(module) }
        return "\(moduleTitle(module)) · \(modeTitle)"
    }

    /// "2"…"10", "A".
    static func upcardLabel(_ upcard: Int) -> String {
        upcard == 11 ? "A" : "\(upcard)"
    }

    /// "16" for hard and soft rows; "8,8", "10,10", "A,A" for pairs.
    static func rowLabel(type: HandType, value: Int) -> String {
        guard type == .pair else { return "\(value)" }
        let card = upcardLabel(value)
        return "\(card),\(card)"
    }

    /// "Hard 16 vs 10", "Soft 18 vs A", "Pair of 8s vs 6", "Pair of Aces vs 2" (as `TrainingText.handLabel`).
    static func cellName(_ cell: TrainingCell) -> String {
        let up = upcardLabel(cell.dealerUpcard)
        switch cell.handType {
        case .hard: return "Hard \(cell.playerValue) vs \(up)"
        case .soft: return "Soft \(cell.playerValue) vs \(up)"
        case .pair:
            let name = cell.playerValue == 11 ? "Aces" : "\(cell.playerValue)s"
            return "Pair of \(name) vs \(up)"
        }
    }

    /// "no decisions", "2 decisions, not enough data", "3 of 7 wrong (43%)".
    static func cellDetail(_ heat: HeatCell?) -> String {
        guard let heat, heat.attempts > 0 else { return "no decisions" }
        guard let rate = heat.errorRate else {
            return heat.attempts == 1 ? "1 decision, not enough data" : "\(heat.attempts) decisions, not enough data"
        }
        return "\(heat.errors) of \(heat.attempts) wrong (\(PercentText.text(rate)))"
    }

    static func cellCaption(_ cell: TrainingCell, _ heat: HeatCell?) -> String {
        "\(cellName(cell)) · \(cellDetail(heat))"
    }

    static func dateTime(_ date: Date, locale: Locale = .autoupdatingCurrent,
                         timeZone: TimeZone = .autoupdatingCurrent) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale, timeZone: timeZone))
    }

    static func dayLabel(_ day: Date) -> String {
        day.formatted(date: .abbreviated, time: .omitted)
    }

    /// "Strategy accuracy, 7 days: 5 days, latest 84%".
    static func chartSummary(module: TrainingModule, range: ProgressRange,
                             points: [ProgressViewModel.ChartPoint]) -> String {
        let head = "\(moduleTitle(module)) accuracy, \(rangeTitle(range).lowercased())"
        guard let last = points.last else { return "\(head): no sessions" }
        let days = points.count == 1 ? "1 day" : "\(points.count) days"
        return "\(head): \(days), latest \(PercentText.text(last.accuracy))"
    }
}
