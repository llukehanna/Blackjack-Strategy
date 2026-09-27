import SwiftUI
import BJSCore

struct TrueCountDrillView: View {
    @Bindable var model: TrueCountDrillViewModel
    let onClose: () -> Void
    let onAgain: () -> Void

    @Environment(PreferencesStore.self) private var preferences
    @Environment(\.scenePhase) private var scenePhase
    @State private var entry = CountEntry()
    @State private var showsLeaveDialog = false
    @State private var workingCheck: GradedCount?

    var body: some View {
        if model.phase == .summary {
            CountSummaryView(summary: model.summary, saveFailed: model.saveFailed, onAgain: onAgain, onDone: onClose)
        } else {
            drill
        }
    }

    private var drill: some View {
        GeometryReader { geo in
            VStack(spacing: FeltSpacing.l) {
                topBar
                Spacer(minLength: 0)
                HStack(alignment: .center, spacing: FeltSpacing.xl) {
                    StatChip(label: "Running count", value: CountingText.signed(model.question.runningCount))
                        .frame(maxWidth: 160)
                    DiscardTray(decksTotal: Double(model.deckCount), decksPlayed: model.decksPlayed)
                }
                Spacer(minLength: 0)
                bottomContent(bottomInset: geo.safeAreaInsets.bottom)
            }
            .padding(.horizontal, FeltSpacing.l)
            .overlay(alignment: .bottom) {
                if case .feedback = model.phase {
                    FeltColor.cream
                        .frame(height: geo.safeAreaInsets.bottom)
                        .offset(y: geo.safeAreaInsets.bottom)
                        .accessibilityHidden(true)
                }
            }
        }
        .onChange(of: showsLeaveDialog) { wasShowing, isShowing in
            if wasShowing && !isShowing { model.resumeAfterInterruption() }
        }
        .onChange(of: scenePhase) { was, now in
            if was != .active && now == .active { model.resumeAfterInterruption() }
        }
        .sensoryFeedback(trigger: model.checks.count) { _, _ in
            guard preferences.hapticsEnabled, let last = model.checks.last else { return nil }
            return last.isCorrect ? .success : .error
        }
        .confirmationDialog("Leave this drill?", isPresented: $showsLeaveDialog, titleVisibility: .visible) {
            Button("Save partial") { model.finish() }
            Button("Discard", role: .destructive, action: onClose)
            Button("Keep going", role: .cancel) {}
        }
        .sheet(item: $workingCheck) { check in
            TrueCountWorkingSheet(question: model.question(for: check), convention: model.convention,
                                  deckCount: model.deckCount, answered: check.answered)
        }
    }

    private var topBar: some View {
        HStack(spacing: FeltSpacing.m) {
            CloseButton(identifier: "counting.close") {
                if model.canSavePartial { showsLeaveDialog = true } else { onClose() }
            }
            Text(model.questionLimit.map { "Question \(model.questionNumber) / \($0)" }
                 ?? "Question \(model.questionNumber)")
                .feltText(.label).foregroundStyle(FeltColor.textTertiary)
                .accessibilityIdentifier("counting.progress")
            Spacer()
            Text("\(model.correctCount) / \(model.checks.count)")
                .feltText(.stat).foregroundStyle(FeltColor.textPrimary)
                .accessibilityLabel("Correct answers")
                .accessibilityValue("\(model.correctCount) of \(model.checks.count)")
            if model.questionLimit == nil {
                Button("END") {
                    if model.checks.isEmpty { onClose() } else { model.finish() }
                }
                .feltText(.label).foregroundStyle(FeltColor.textPrimary)
                .frame(minWidth: FeltTapTarget.minimum, minHeight: FeltTapTarget.minimum)
                .accessibilityIdentifier("counting.end")
            }
        }
    }

    @ViewBuilder private func bottomContent(bottomInset: CGFloat) -> some View {
        switch model.phase {
        case .question:
            CountKeypad(entry: $entry, allowsHalf: model.allowsHalf) { model.submit($0) }
                // Without .5, the keypad's blank placeholder key would stretch into the free height.
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, bottomInset > 0 ? 0 : FeltSpacing.l)
        case .feedback(let graded):
            let text = CountingText.trueFeedback(question: model.question(for: graded), convention: model.convention,
                                                 answered: graded.answered, isCorrect: graded.isCorrect)
            FeedbackCard(verdict: graded.isCorrect ? .correct : .incorrect, headline: text.headline,
                         reason: text.reason, onWhy: { workingCheck = graded }, onNext: { model.next() })
                .padding(.horizontal, -FeltSpacing.l)
        case .summary:
            EmptyView()
        }
    }
}
