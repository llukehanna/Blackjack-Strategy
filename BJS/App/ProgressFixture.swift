#if DEBUG
import Foundation
import BJSCore

/// A deterministic saved history for the Progress UI test and design-check screenshots
/// (Step 6 spec §5). DEBUG and `-uiTesting` only.
///
/// Under the default rules (6D S17 DAS 3:2), with the 7-day range:
/// - Strategy is 22 of 33 = 67%; RC and TC are 2 of 3 = 67% each; Shoe has no data.
/// - All time, Strategy is 24 of 35 = 69%.
/// - Heat map: hard 16 vs 10 severe, hard 11 vs 6 low, hard 12 vs 4 none, soft 18 vs 9 high,
///   8,8 vs A medium, and one hard 4 decision.
/// - The day-3 Learn session is in history but not in the stats.
enum ProgressFixture {
    typealias Spec = (cell: TrainingCell, chosen: RecordedChoice, correct: Action)

    static func drafts(now: Date, calendar: Calendar = .current) -> [SessionDraft] {
        let rules = BlackjackRules()
        let today = calendar.startOfDay(for: now)
        let halfToday = now.timeIntervalSince(today) / 2
        /// Halfway through today's elapsed time, `daysAgo` calendar days back: always inside that day.
        func start(_ daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: today)!.addingTimeInterval(halfToday)
        }
        func cell(_ type: HandType, _ value: Int, _ upcard: Int) -> TrainingCell {
            TrainingCell(handType: type, playerValue: value, dealerUpcard: upcard)
        }
        func right(_ c: TrainingCell, _ action: Action) -> Spec { (c, .action(action), action) }
        func wrong(_ c: TrainingCell, _ chose: Action, _ correct: Action) -> Spec { (c, .action(chose), correct) }

        let h16 = cell(.hard, 16, 10), h11 = cell(.hard, 11, 6), h12 = cell(.hard, 12, 4)
        let s18 = cell(.soft, 18, 9), p8 = cell(.pair, 8, 11), h4 = cell(.hard, 4, 5), h13 = cell(.hard, 13, 2)
        let w16 = wrong(h16, .stand, .hit), r16 = right(h16, .hit)
        let r11 = right(h11, .double), w11 = wrong(h11, .hit, .double)
        let r12 = right(h12, .stand)
        let r18 = right(s18, .hit), w18 = wrong(s18, .stand, .hit)
        let r8 = right(p8, .split), w8 = wrong(p8, .hit, .split)
        let r4 = right(h4, .hit)
        let t13: Spec = (h13, .timeout, .stand)

        func strategy(_ daysAgo: Int, mode: String = "test", _ specs: [Spec]) -> SessionDraft {
            let s = start(daysAgo)
            return SessionDraft(module: .strategy, mode: mode, startedAt: s, endedAt: s.addingTimeInterval(300),
                                rules: rules, decisions: specs.enumerated().map { i, d in
                DecisionDraft(handNumber: i + 1, cell: d.cell, chosen: d.chosen, correctAction: d.correct,
                              isCorrect: d.chosen == .action(d.correct), responseMs: 1_500,
                              decidedAt: s.addingTimeInterval(Double(i + 1)))
            })
        }
        func counting(_ module: TrainingModule, mode: String?, _ daysAgo: Int, kind: CountKind,
                      _ values: [(expected: Double, answered: Double, correct: Bool, cards: Int)]) -> SessionDraft {
            let s = start(daysAgo).addingTimeInterval(-60)
            return SessionDraft(module: module, mode: mode, startedAt: s, endedAt: s.addingTimeInterval(120),
                                rules: rules, countChecks: values.enumerated().map { i, v in
                CountCheckDraft(kind: kind, expected: v.expected, answered: v.answered, isCorrect: v.correct,
                                responseMs: 2_000, cardsSeen: v.cards, checkedAt: s.addingTimeInterval(Double(i + 1)))
            })
        }

        return [
            strategy(0, [w16, w16, r16, r11, r11, r12, w18]),
            strategy(1, [w16, r11, r11, w11, r8, r8, r4]),
            strategy(2, [w16, r16, r11, r11, r12, r18, t13]),
            strategy(3, mode: "learn", [r16, r16, r11, r12, r18]),
            strategy(4, [w16, r11, r11, w8, r8, r18, r12]),
            strategy(6, [w16, r11, w18, r18, r12]),
            strategy(9, [r16, r11]),
            counting(.countingRC, mode: nil, 1, kind: .runningCount,
                     [(3, 3, true, 10), (5, 4, false, 20), (2, 2, true, 26)]),
            counting(.countingTC, mode: TrueCountConvention.exact.rawValue, 2, kind: .trueCount,
                     [(2.8, 3, true, 104), (-1.5, -1, false, 156), (1, 1, true, 208)]),
        ]
    }

    static func seed(into store: SessionStore, now: Date, calendar: Calendar = .current) {
        for draft in drafts(now: now, calendar: calendar) {
            try? store.save(draft)
        }
    }
}
#endif
