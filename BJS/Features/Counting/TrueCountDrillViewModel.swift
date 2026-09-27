import Foundation
import Observation
import os
import BJSCore

enum TrueCountPhase: Equatable {
    case question
    case feedback(GradedCount)
    case summary
}

/// Runs a true-count drill (Step 4 spec §4). BJSCore generates and grades the questions; this type
/// sequences phases and persists. The convention is snapshotted at start.
@MainActor
@Observable
final class TrueCountDrillViewModel {
    typealias QuestionMaker = (Int, inout SeededRandomNumberGenerator) -> TrueCountQuestion

    static let defaultQuestionMaker: QuestionMaker = { deckCount, rng in
        CountDrillGenerator.trueCountQuestion(deckCount: deckCount, using: &rng)
    }

    let setup: TrueCountSetup
    let rules: BlackjackRules
    let convention: TrueCountConvention
    let sessionID = UUID()
    let startedAt: Date

    private(set) var phase: TrueCountPhase = .question
    private(set) var question: TrueCountQuestion
    private(set) var questionNumber = 1
    private(set) var checks: [GradedCount] = []
    private(set) var answerStartedAt: Date
    private(set) var hasSaved = false
    private(set) var saveFailed = false
    private(set) var endedAt: Date?

    /// The question each check answered, parallel to `checks`.
    @ObservationIgnored private var askedQuestions: [TrueCountQuestion] = []
    @ObservationIgnored private var rng: SeededRandomNumberGenerator
    @ObservationIgnored private let makeQuestion: QuestionMaker
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let persist: (SessionDraft) throws -> Void
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "TrueCountDrill")

    init(setup: TrueCountSetup, rules: BlackjackRules, convention: TrueCountConvention, seed: UInt64,
         now: @escaping () -> Date = { Date() }, makeQuestion: QuestionMaker? = nil,
         persist: @escaping (SessionDraft) throws -> Void) {
        self.setup = setup
        self.rules = rules
        self.convention = convention
        self.now = now
        self.persist = persist
        let maker = makeQuestion ?? Self.defaultQuestionMaker
        self.makeQuestion = maker
        var rng = SeededRandomNumberGenerator(seed: seed)
        self.question = maker(rules.deckCount.rawValue, &rng)
        self.rng = rng
        let start = now()
        self.startedAt = start
        self.answerStartedAt = start
    }

    // MARK: - Display

    var questionLimit: Int? { setup.length.questionLimit }
    var deckCount: Int { rules.deckCount.rawValue }
    var decksPlayed: Double { Double(deckCount) - question.decksRemaining }
    /// Only Exact accepts halves (parent spec §5).
    var allowsHalf: Bool { convention == .exact }
    var correctCount: Int { checks.filter(\.isCorrect).count }
    var canSavePartial: Bool { !checks.isEmpty && phase != .summary }

    func question(for check: GradedCount) -> TrueCountQuestion { askedQuestions[check.id] }

    var sessionDraft: SessionDraft {
        SessionDraft(id: sessionID, module: .countingTC, mode: convention.rawValue, startedAt: startedAt,
                     endedAt: endedAt ?? now(), rules: rules, countChecks: checks.map(\.draft))
    }

    var summary: CountSummaryModel {
        CountSummaryModel(
            title: "True count", rowsTitle: "Questions",
            score: CountDrillScore(checks.map { (expected: $0.expected, answered: $0.answered, isCorrect: $0.isCorrect) }),
            secondsPerCard: nil,
            rows: checks.map { CountingText.trueRow($0, question: question(for: $0), convention: convention) })
    }

    // MARK: - Input

    /// Keypad ENTER.
    func submit(_ answer: Double) {
        guard phase == .question else { return }
        let checkedAt = now()
        let graded = GradedCount(
            id: checks.count, kind: .trueCount, expected: question.target(for: convention), answered: answer,
            isCorrect: question.isCorrect(answer, convention: convention),
            responseMs: GradedCount.milliseconds(from: answerStartedAt, to: checkedAt),
            cardsSeen: Int((decksPlayed * 52).rounded()), checkedAt: checkedAt)
        checks.append(graded)
        askedQuestions.append(question)
        phase = .feedback(graded)
    }

    /// FeedbackCard NEXT: the next question, or the summary when the length is reached.
    func next() {
        guard case .feedback = phase else { return }
        if let questionLimit, checks.count >= questionLimit {
            finish()
            return
        }
        questionNumber += 1
        question = makeQuestion(deckCount, &rng)
        answerStartedAt = now()
        phase = .question
    }

    /// After the leave dialog closes or the app returns to the foreground: restart the answer clock.
    func resumeAfterInterruption() {
        guard phase == .question else { return }
        answerStartedAt = now()
    }

    /// Ends the drill (limit, END, or Save partial): shows the summary and saves once.
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
            logger.error("True count drill failed to save: \(error.localizedDescription)")
        }
    }
}
