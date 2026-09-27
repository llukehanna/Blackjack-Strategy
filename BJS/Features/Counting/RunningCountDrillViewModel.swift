import Foundation
import Observation
import os
import BJSCore

enum RunningCountPhase: Equatable {
    /// A group is on screen; the view's timer calls `advance(token:)` after `pace`.
    case presenting(group: Int)
    /// A checkpoint: the keypad is up.
    case answering(group: Int)
    case feedback(GradedCount)
    case summary
}

/// Runs a running-count drill (Step 4 spec §4). BJSCore builds the drill and knows the counts;
/// this type sequences phases, owns the presentation token, and persists.
@MainActor
@Observable
final class RunningCountDrillViewModel {
    let setup: RunningCountSetup
    let rules: BlackjackRules
    let drill: RunningCountDrill
    /// Seconds each group stays on screen.
    let pace: Double
    let sessionID = UUID()
    let startedAt: Date

    private(set) var phase: RunningCountPhase = .presenting(group: 0)
    private(set) var checks: [GradedCount] = []
    /// Bumps whenever a group's interval (re)starts. The view's timer hands it back to `advance`.
    private(set) var presentationToken = 0
    private(set) var answerStartedAt: Date
    private(set) var hasSaved = false
    private(set) var saveFailed = false
    private(set) var endedAt: Date?

    /// The group each check came after, parallel to `checks`.
    @ObservationIgnored private var checkGroups: [Int] = []
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let persist: (SessionDraft) throws -> Void
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "RunningCountDrill")

    convenience init(setup: RunningCountSetup, rules: BlackjackRules, paceOverride: Double? = nil, seed: UInt64,
                     now: @escaping () -> Date = { Date() },
                     persist: @escaping (SessionDraft) throws -> Void) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let drill = CountDrillGenerator.runningCountDrill(
            length: setup.length.drillLength, groupSize: setup.groupSize, deckCount: rules.deckCount.rawValue,
            randomCheckpoints: setup.randomCheckpoints, using: &rng)
        self.init(setup: setup, rules: rules, drill: drill, paceOverride: paceOverride, now: now, persist: persist)
    }

    init(setup: RunningCountSetup, rules: BlackjackRules, drill: RunningCountDrill, paceOverride: Double? = nil,
         now: @escaping () -> Date = { Date() }, persist: @escaping (SessionDraft) throws -> Void) {
        self.setup = setup
        self.rules = rules
        self.drill = drill
        self.pace = paceOverride ?? setup.pace
        self.now = now
        self.persist = persist
        let start = now()
        self.startedAt = start
        self.answerStartedAt = start
        present(0)
    }

    // MARK: - Display

    var visibleCards: [Card] {
        guard case .presenting(let group) = phase else { return [] }
        return drill.groups[group]
    }

    var cardsShown: Int {
        switch phase {
        case .presenting(let group), .answering(let group): return cardsThrough(group)
        case .feedback(let graded): return graded.cardsSeen
        case .summary: return checks.last?.cardsSeen ?? 0
        }
    }

    var totalCards: Int { drill.cardCount }
    var correctCount: Int { checks.filter(\.isCorrect).count }
    /// Whether "Save partial" has anything to save right now.
    var canSavePartial: Bool { !checks.isEmpty && phase != .summary }

    func trace(for check: GradedCount) -> [CountTraceEntry] {
        drill.trace(throughGroup: checkGroups[check.id])
    }

    var sessionDraft: SessionDraft {
        SessionDraft(id: sessionID, module: .countingRC, mode: nil, startedAt: startedAt,
                     endedAt: endedAt ?? now(), rules: rules, countChecks: checks.map(\.draft))
    }

    var summary: CountSummaryModel {
        CountSummaryModel(
            title: "Running count", rowsTitle: "Checkpoints",
            score: CountDrillScore(checks.map { (expected: $0.expected, answered: $0.answered, isCorrect: $0.isCorrect) }),
            secondsPerCard: CountDrillScore.secondsPerCard(pace: pace, groupSize: setup.groupSize),
            rows: checks.map(CountingText.runningRow))
    }

    // MARK: - Input

    /// The view's timer fired after `pace` for the presentation identified by `token`.
    func advance(token: Int) {
        guard case .presenting(let group) = phase, token == presentationToken else { return }
        if drill.checkpoints.contains(group) {
            answerStartedAt = now()
            phase = .answering(group: group)
        } else {
            present(group + 1)
        }
    }

    /// Keypad ENTER at a checkpoint.
    func submit(_ answer: Double) {
        guard case .answering(let group) = phase else { return }
        let checkedAt = now()
        let expected = Double(drill.expectedCount(afterGroup: group))
        let graded = GradedCount(
            id: checks.count, kind: .runningCount, expected: expected, answered: answer,
            isCorrect: answer == expected,
            responseMs: GradedCount.milliseconds(from: answerStartedAt, to: checkedAt),
            cardsSeen: cardsThrough(group), checkedAt: checkedAt)
        checks.append(graded)
        checkGroups.append(group)
        phase = .feedback(graded)
    }

    /// FeedbackCard NEXT: resume with the next group, or finish after the last.
    func next() {
        guard case .feedback = phase, let group = checkGroups.last else { return }
        if group + 1 < drill.groups.count {
            present(group + 1)
        } else {
            finish()
        }
    }

    /// After the leave dialog closes or the app returns to the foreground: the current group gets a
    /// fresh full interval, or the answer clock restarts. A no-op in other phases.
    func resumeAfterInterruption() {
        switch phase {
        case .presenting(let group): present(group)
        case .answering: answerStartedAt = now()
        case .feedback, .summary: break
        }
    }

    /// Ends the drill (last checkpoint or Save partial): shows the summary and saves once.
    /// A drill with no checks isn't saved.
    func finish() {
        guard phase != .summary else { return }
        endedAt = now()
        phase = .summary
        guard !checks.isEmpty, !hasSaved else { return }
        hasSaved = true
        do {
            try persist(sessionDraft)
        } catch {
            saveFailed = true
            logger.error("Running count drill failed to save: \(error.localizedDescription)")
        }
    }

    // MARK: - Internals

    private func present(_ group: Int) {
        presentationToken += 1
        phase = .presenting(group: group)
    }

    private func cardsThrough(_ group: Int) -> Int {
        drill.groups[0...group].reduce(0) { $0 + $1.count }
    }
}
