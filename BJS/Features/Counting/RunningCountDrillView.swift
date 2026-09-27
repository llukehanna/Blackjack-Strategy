import SwiftUI
import BJSCore

struct RunningCountDrillView: View {
    @Bindable var model: RunningCountDrillViewModel
    let onClose: () -> Void
    let onAgain: () -> Void

    @Environment(PreferencesStore.self) private var preferences
    @Environment(\.scenePhase) private var scenePhase
    @State private var entry = CountEntry()
    @State private var showsLeaveDialog = false
    @State private var traceCheck: GradedCount?

    /// Three cards and two gaps fit the SE's 343 pt content width.
    private static let cardWidth: CGFloat = 96

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
                cardArea
                Spacer(minLength: 0)
                bottomContent(bottomInset: geo.safeAreaInsets.bottom)
            }
            .padding(.horizontal, FeltSpacing.l)
            .overlay(alignment: .bottom) {
                // Carry the FeedbackCard's cream down through the home-indicator area.
                if case .feedback = model.phase {
                    FeltColor.cream
                        .frame(height: geo.safeAreaInsets.bottom)
                        .offset(y: geo.safeAreaInsets.bottom)
                        .accessibilityHidden(true)
                }
            }
        }
        .task(id: "\(model.presentationToken)-\(showsLeaveDialog)-\(scenePhase == .active)") {
            await runPresentationTimer()
        }
        .onChange(of: showsLeaveDialog) { wasShowing, isShowing in
            // The timer pauses behind the dialog; the current group gets a fresh interval on return.
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
        .sheet(item: $traceCheck) { check in
            CountTraceSheet(entries: model.trace(for: check), check: check)
        }
    }

    private var topBar: some View {
        HStack(spacing: FeltSpacing.m) {
            CloseButton(identifier: "counting.close") {
                if model.canSavePartial { showsLeaveDialog = true } else { onClose() }
            }
            Text("Card \(model.cardsShown) / \(model.totalCards)")
                .feltText(.label).foregroundStyle(FeltColor.textTertiary)
                .accessibilityIdentifier("counting.progress")
            Spacer()
            Text("\(model.correctCount) / \(model.checks.count)")
                .feltText(.stat).foregroundStyle(FeltColor.textPrimary)
                .accessibilityLabel("Correct checks")
                .accessibilityValue("\(model.correctCount) of \(model.checks.count)")
        }
    }

    @ViewBuilder private var cardArea: some View {
        switch model.phase {
        case .presenting:
            HStack(spacing: FeltSpacing.m) {
                ForEach(Array(model.visibleCards.enumerated()), id: \.offset) { _, card in
                    PlayingCard(card: card, width: Self.cardWidth)
                }
            }
            // A fresh identity per group, so a repeated card still reads as a new deal.
            .id(model.presentationToken)
        case .answering:
            Text("Running count?").feltText(.title).foregroundStyle(FeltColor.textPrimary)
        case .feedback, .summary:
            EmptyView()
        }
    }

    @ViewBuilder private func bottomContent(bottomInset: CGFloat) -> some View {
        switch model.phase {
        case .answering:
            CountKeypad(entry: $entry, allowsHalf: false) { model.submit($0) }
                // Without .5, the keypad's blank placeholder key would stretch into the free height.
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, bottomInset > 0 ? 0 : FeltSpacing.l)
        case .feedback(let graded):
            let text = CountingText.runningFeedback(expected: Int(graded.expected), answered: Int(graded.answered))
            FeedbackCard(verdict: graded.isCorrect ? .correct : .incorrect, headline: text.headline,
                         reason: text.reason, onWhy: { traceCheck = graded }, onNext: { model.next() })
                .padding(.horizontal, -FeltSpacing.l)
        case .presenting, .summary:
            EmptyView()
        }
    }

    private func runPresentationTimer() async {
        guard case .presenting = model.phase, !showsLeaveDialog, scenePhase == .active else { return }
        let token = model.presentationToken
        try? await Task.sleep(for: .seconds(model.pace))
        guard !Task.isCancelled else { return }
        model.advance(token: token)
    }
}
