import Foundation
import BJSCore

/// Display values for one saved session (Step 6 spec §3). A value type: the detail doesn't
/// change while it's on screen.
struct SessionDetailViewModel {
    struct Chip: Equatable, Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    struct MistakeRow: Identifiable {
        let id: Int
        let label: String
        let value: String
        let why: WhyContext
    }

    struct CheckRow: Equatable, Identifiable {
        let id: Int
        let label: String
        let value: String
    }

    static let learnCaption = "Learn mode · not counted in your stats"
    static let traceFootnote = "The card-by-card trace isn't kept after a drill ends."

    let title: String
    let dateText: String
    let captions: [String]
    let chips: [Chip]
    let mistakes: [MistakeRow]
    let checks: [CheckRow]
    let showsTraceFootnote: Bool

    init(detail: SessionDetail, engine: StrategyEngine = StrategyEngine()) {
        let module = detail.sample.module
        title = ProgressText.sessionTitle(module: module, mode: detail.mode)
        dateText = ProgressText.dateTime(detail.sample.startedAt)

        var captions = [RulesSummary.text(for: detail.rules)]
        if detail.mode == "learn" { captions.append(Self.learnCaption) }
        if module == .countingTC, let mode = detail.mode, let convention = TrueCountConvention(rawValue: mode) {
            captions.append(TrainingText.conventionRule(convention))
        }
        self.captions = captions

        let accuracy = ProgressViewModel.accuracyText(detail.sample)
        switch module {
        case .strategy, .shoe:
            var chips = [Chip(label: "Accuracy", value: accuracy),
                         Chip(label: "Mistakes", value: "\(detail.decisions.filter { !$0.isCorrect }.count)"),
                         Chip(label: "Best streak", value: "\(detail.bestStreak)"),
                         Chip(label: "Decisions", value: "\(detail.sample.decisionCount)")]
            if detail.mode == "speed", let ms = detail.meanResponseMs {
                chips.append(Chip(label: "Avg decision", value: String(format: "%.1f s", ms / 1000)))
            }
            self.chips = chips
        case .countingRC, .countingTC:
            let score = CountDrillScore(detail.checks.map {
                (expected: $0.sample.expected, answered: $0.sample.answered, isCorrect: $0.sample.isCorrect)
            })
            self.chips = [Chip(label: "Accuracy", value: accuracy),
                          Chip(label: "Correct", value: "\(score.correct) / \(score.checks)"),
                          Chip(label: "Mean error", value: TrainingText.meanError(score.meanAbsoluteError))]
        }

        let table = engine.strategy(for: detail.rules)
        mistakes = detail.decisions.enumerated().compactMap { index, decision in
            guard !decision.isCorrect else { return nil }
            let userAction: Action?
            let chosenName: String
            switch decision.chosen {
            case .timeout:
                userAction = nil
                chosenName = "Time's up"
            case .action(let action):
                userAction = action
                chosenName = TrainingText.actionName(action)
            }
            let why = WhyContext(cell: decision.cell, userAction: userAction, correctAction: decision.correctAction,
                                 rules: detail.rules, table: table)
            return MistakeRow(id: index, label: TrainingText.handLabel(why),
                              value: "\(chosenName) → \(TrainingText.actionName(decision.correctAction))", why: why)
        }

        checks = detail.checks.enumerated().map { index, check in
            let s = check.sample
            switch s.kind {
            case .runningCount:
                let expected = TrainingText.signed(Int(s.expected))
                return CheckRow(id: index, label: "After card \(check.cardsSeen)",
                                value: s.isCorrect ? expected : "\(expected) · you said \(TrainingText.signed(Int(s.answered)))")
            case .trueCount:
                let target = TrainingText.signed(s.expected)
                return CheckRow(id: index, label: "Check \(index + 1)",
                                value: s.isCorrect ? target : "\(target) · you said \(TrainingText.signed(s.answered))")
            }
        }
        showsTraceFootnote = module == .countingRC || module == .countingTC
    }
}
