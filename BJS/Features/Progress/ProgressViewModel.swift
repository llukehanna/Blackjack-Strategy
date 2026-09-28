import Foundation
import Observation
import os
import BJSCore

/// Maps saved progress to the Progress tab's display values (Step 6 spec §2, §5).
@Observable
final class ProgressViewModel {
    struct Chip: Equatable, Identifiable {
        let module: TrainingModule
        let value: String
        var id: TrainingModule { module }
        var label: String { ProgressText.moduleTitle(module) }
    }

    struct ChartPoint: Equatable, Identifiable {
        let day: Date
        let accuracy: Double
        var id: Date { day }
    }

    struct HistoryRow: Equatable, Identifiable {
        let id: UUID
        let title: String
        let dateText: String
        let accuracy: String
    }

    static let modules: [TrainingModule] = [.strategy, .countingRC, .countingTC, .shoe]
    /// The heat map covers every graded strategy decision: the Strategy trainer's and Shoe Sim's.
    static let heatModules: Set<TrainingModule> = [.strategy, .shoe]
    static let handTypes: [HandType] = [.hard, .soft, .pair]
    static let columnLabels = HeatMapLayout.upcards.map { ProgressText.upcardLabel($0) }

    var range: ProgressRange = .week
    var trendModule: TrainingModule = .strategy
    var heatType: HandType = .hard {
        didSet { if heatType != oldValue { selectedCell = nil } }
    }
    private(set) var selectedCell: TrainingCell?

    private(set) var hasAnySessions = false
    private(set) var loadFailed = false
    private(set) var chips: [Chip] = ProgressViewModel.modules.map { Chip(module: $0, value: PercentText.noData) }
    private(set) var history: [HistoryRow] = []
    private(set) var heat: [TrainingCell: HeatCell] = [:]
    private var trends: [TrainingModule: [ChartPoint]] = [:]
    private var rangeStart: Date?
    private var endOfToday: Date?

    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "ProgressViewModel")

    /// What each module's accuracy counts: decisions, count checks, or both for Shoe Sim.
    static func measure(_ module: TrainingModule) -> ProgressStats.Measure {
        switch module {
        case .strategy: return .decisions
        case .countingRC, .countingTC: return .countChecks
        case .shoe: return .combined
        }
    }

    /// One session's accuracy, measured as its module is.
    static func accuracyText(_ session: SessionSample) -> String {
        PercentText.text(ProgressStats.headline(sessions: [session], modules: [session.module],
                                                measure: measure(session.module), since: nil).accuracy)
    }

    var chartPoints: [ChartPoint] { trends[trendModule] ?? [] }

    /// From the range start (or the first point, for all time) to the end of today.
    var chartDomain: ClosedRange<Date>? {
        guard let start = rangeStart ?? chartPoints.first?.day, let endOfToday, start < endOfToday else { return nil }
        return start...endOfToday
    }

    var chartSummary: String {
        ProgressText.chartSummary(module: trendModule, range: range, points: chartPoints)
    }

    var hasHeatData: Bool { !heat.isEmpty }

    var gridRows: [HeatMapGrid.Row] {
        HeatMapLayout.rows(for: heatType, cells: heat).map { value in
            HeatMapGrid.Row(id: value, label: ProgressText.rowLabel(type: heatType, value: value),
                            cells: HeatMapLayout.upcards.map { upcard in
                let cell = TrainingCell(handType: heatType, playerValue: value, dealerUpcard: upcard)
                return HeatMapGrid.Cell(id: upcard, bin: HeatBin(heat[cell]),
                                        accessibilityLabel: ProgressText.cellName(cell),
                                        accessibilityValue: ProgressText.cellDetail(heat[cell]),
                                        isSelected: cell == selectedCell)
            })
        }
    }

    var caption: String? {
        selectedCell.map { ProgressText.cellCaption($0, heat[$0]) }
    }

    /// Selects the cell, or clears the selection when it's already selected.
    func select(row: Int, column: Int) {
        let cell = TrainingCell(handType: heatType, playerValue: row, dealerUpcard: column)
        selectedCell = selectedCell == cell ? nil : cell
    }

    /// Maps samples to display values. Filters to `range` itself, so callers may pass unfiltered samples.
    func apply(entries: [HistoryEntry], sessions: [SessionSample], decisions: [DecisionSample],
               now: Date, calendar: Calendar) {
        let since = range.since(now: now, calendar: calendar)
        rangeStart = since
        endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        hasAnySessions = !entries.isEmpty
        chips = Self.modules.map { module in
            Chip(module: module, value: PercentText.text(ProgressStats.headline(
                sessions: sessions, modules: [module], measure: Self.measure(module), since: since).accuracy))
        }
        trends = Dictionary(uniqueKeysWithValues: Self.modules.map { module in
            (module, ProgressStats.dailyTrend(sessions: sessions, modules: [module], measure: Self.measure(module),
                                              since: since, calendar: calendar)
                .map { ChartPoint(day: $0.day, accuracy: $0.accuracy) })
        })
        heat = ProgressStats.heatMap(decisions.filter { since == nil || $0.date >= since! })
        history = entries.map { entry in
            HistoryRow(id: entry.id,
                       title: ProgressText.sessionTitle(module: entry.sample.module, mode: entry.mode),
                       dateText: ProgressText.dateTime(entry.sample.startedAt),
                       accuracy: Self.accuracyText(entry.sample))
        }
    }

    /// Reads the store for the current range. A failed fetch shows `ProgressText.loadFailed`, never crashes.
    func reload(store: SessionStore, now: Date = .now, calendar: Calendar = .current) {
        let since = range.since(now: now, calendar: calendar)
        do {
            apply(entries: try store.historyEntries(),
                  sessions: try store.sessionSamples(since: since),
                  decisions: try store.decisionSamples(modules: Self.heatModules, since: since),
                  now: now, calendar: calendar)
            loadFailed = false
        } catch {
            logger.error("Progress failed to load: \(error.localizedDescription)")
            apply(entries: [], sessions: [], decisions: [], now: now, calendar: calendar)
            loadFailed = true
        }
    }
}
