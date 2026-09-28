import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct ProgressTextTests {

    @Test("Session titles combine module and mode")
    func sessionTitles() {
        #expect(ProgressText.sessionTitle(module: .strategy, mode: "test") == "Strategy · Test")
        #expect(ProgressText.sessionTitle(module: .strategy, mode: "learn") == "Strategy · Learn")
        #expect(ProgressText.sessionTitle(module: .strategy, mode: "weakSpots") == "Strategy · Weak spots")
        #expect(ProgressText.sessionTitle(module: .countingRC, mode: nil) == "Running count")
        #expect(ProgressText.sessionTitle(module: .countingTC, mode: "exact") == "True count · Exact")
        #expect(ProgressText.sessionTitle(module: .countingTC, mode: "floor") == "True count · Floor")
        #expect(ProgressText.sessionTitle(module: .strategy, mode: "unknown") == "Strategy")
        #expect(ProgressText.sessionTitle(module: .shoe, mode: nil) == "Shoe Sim")
    }

    @Test("Range, module and hand-type titles")
    func titles() {
        #expect(ProgressRange.allCases.map(ProgressText.rangeTitle) == ["7 days", "30 days", "All time"])
        #expect(ProgressViewModel.modules.map(ProgressText.moduleTitle)
                == ["Strategy", "Running count", "True count", "Shoe Sim"])
        #expect(ProgressViewModel.modules.map(ProgressText.moduleShortTitle) == ["Strategy", "Running", "True", "Shoe"])
        #expect(ProgressViewModel.handTypes.map(ProgressText.handTypeTitle) == ["Hard", "Soft", "Pairs"])
    }

    @Test("Grid labels")
    func gridLabels() {
        #expect(ProgressViewModel.columnLabels == ["2", "3", "4", "5", "6", "7", "8", "9", "10", "A"])
        #expect(ProgressText.rowLabel(type: .hard, value: 16) == "16")
        #expect(ProgressText.rowLabel(type: .soft, value: 12) == "12")
        #expect(ProgressText.rowLabel(type: .pair, value: 8) == "8,8")
        #expect(ProgressText.rowLabel(type: .pair, value: 10) == "10,10")
        #expect(ProgressText.rowLabel(type: .pair, value: 11) == "A,A")
    }

    @Test("Cell names match the WHY sheet's hand labels")
    func cellNames() {
        #expect(ProgressText.cellName(TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)) == "Hard 16 vs 10")
        #expect(ProgressText.cellName(TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 11)) == "Soft 18 vs A")
        #expect(ProgressText.cellName(TrainingCell(handType: .pair, playerValue: 8, dealerUpcard: 6)) == "Pair of 8s vs 6")
        #expect(ProgressText.cellName(TrainingCell(handType: .pair, playerValue: 11, dealerUpcard: 2)) == "Pair of Aces vs 2")
    }

    @Test("Cell captions: no decisions, not enough data, and the error count")
    func captions() {
        let cell = TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10)
        #expect(ProgressText.cellCaption(cell, nil) == "Hard 16 vs 10 · no decisions")
        #expect(ProgressText.cellCaption(cell, HeatCell(attempts: 1, errors: 0, errorRate: nil))
                == "Hard 16 vs 10 · 1 decision, not enough data")
        #expect(ProgressText.cellCaption(cell, HeatCell(attempts: 2, errors: 1, errorRate: nil))
                == "Hard 16 vs 10 · 2 decisions, not enough data")
        #expect(ProgressText.cellCaption(cell, HeatCell(attempts: 7, errors: 3, errorRate: 3.0 / 7))
                == "Hard 16 vs 10 · 3 of 7 wrong (43%)")
        #expect(ProgressText.cellDetail(HeatCell(attempts: 7, errors: 3, errorRate: 3.0 / 7)) == "3 of 7 wrong (43%)")
    }

    @Test("Chart summary for VoiceOver")
    func chartSummary() {
        let points = [ProgressViewModel.ChartPoint(day: .distantPast, accuracy: 0.5),
                      ProgressViewModel.ChartPoint(day: .now, accuracy: 0.84)]
        #expect(ProgressText.chartSummary(module: .strategy, range: .week, points: points)
                == "Strategy accuracy, 7 days: 2 days, latest 84%")
        #expect(ProgressText.chartSummary(module: .countingRC, range: .allTime, points: [points[1]])
                == "Running count accuracy, all time: 1 day, latest 84%")
        #expect(ProgressText.chartSummary(module: .shoe, range: .month, points: [])
                == "Shoe Sim accuracy, 30 days: no sessions")
    }

    @Test("Every StrategyMode and TrueCountConvention raw value has a title — a drift guard for modeTitle's hard-coded raw values")
    func modeTitleCoversEveryRawValue() {
        for mode in StrategyMode.allCases {
            let title = ProgressText.modeTitle(mode.rawValue, module: .strategy)
            #expect(title != nil, "StrategyMode.\(mode.rawValue) has no title")
        }
        for convention in TrueCountConvention.allCases {
            let title = ProgressText.modeTitle(convention.rawValue, module: .countingTC)
            #expect(title != nil, "TrueCountConvention.\(convention.rawValue) has no title")
        }
    }

    @Test("Dates use the abbreviated date and short time")
    func dateTime() {
        let text = ProgressText.dateTime(Date(timeIntervalSince1970: 0), locale: Locale(identifier: "en_US"),
                                         timeZone: TimeZone(identifier: "UTC")!)
        #expect(text.contains("1970"))
        #expect(text.contains("Jan"))
        #expect(text.contains("12:00"))
    }
}
