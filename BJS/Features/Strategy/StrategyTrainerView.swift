import SwiftUI
import BJSCore

struct StrategyTrainerView: View {
    @Bindable var model: StrategyTrainerViewModel
    let onClose: () -> Void
    let onAgain: () -> Void

    @Environment(PreferencesStore.self) private var preferences
    @State private var showsToast = false
    @State private var showsLeaveDialog = false
    @State private var whyContext: WhyContext?

    var body: some View {
        if model.phase == .summary {
            StrategySummaryView(summary: model.summary, handsTarget: model.handLimit, mode: model.setup.mode,
                                saveFailed: model.saveFailed, onWhy: { whyContext = $0.why },
                                onAgain: onAgain, onDone: onClose)
                .sheet(item: $whyContext) { WhySheet(context: $0) }
        } else {
            table
        }
    }

    private var table: some View {
        GeometryReader { geo in
            let isAwaiting = model.phase == .awaitingDecision
            VStack(spacing: FeltSpacing.l) {
                topBar
                if model.setup.mode.isTimed {
                    // The slot stays reserved between decisions so the table doesn't jump when the
                    // bar hides for feedback and the outcome. It also hides behind the leave dialog,
                    // where the Speed timer is paused (the clock restarts on "Keep playing").
                    let showsBar = isAwaiting && !showsLeaveDialog
                    CountdownBar(startedAt: model.decisionStartedAt, duration: model.speedTimerSeconds)
                        .opacity(showsBar ? 1 : 0)
                        .accessibilityHidden(!showsBar)
                }
                DealerHandView(cards: model.dealerCards, isRevealed: model.isDealerRevealed,
                               total: model.isDealerRevealed ? model.round?.dealer.total : nil,
                               cardWidth: SplitHandsLayout.maxCardWidth)
                Spacer(minLength: 0)
                    .overlay {
                        // In the felt between the dealer and the player, clear of both hands.
                        if showsToast { FeltToast(text: "Correct").fixedSize().transition(.opacity) }
                    }
                SplitHandsView(hands: model.playerHands.map { $0.hand.cards },
                               totals: model.playerHands.map { "\($0.hand.total)" },
                               activeIndex: isAwaiting ? model.activeHandIndex : nil,
                               availableWidth: geo.size.width - 2 * FeltSpacing.l)
                Spacer(minLength: 0)
                bottom(bottomInset: geo.safeAreaInsets.bottom)
            }
            .padding(.horizontal, FeltSpacing.l)
            .overlay(alignment: .bottom) {
                // The FeedbackCard is bottom-anchored: carry its cream down through the
                // home-indicator area instead of leaving a strip of felt under it.
                if case .feedback = model.phase {
                    FeltColor.cream
                        .frame(height: geo.safeAreaInsets.bottom)
                        .offset(y: geo.safeAreaInsets.bottom)
                        .accessibilityHidden(true)
                }
            }
        }
        .task(id: "\(model.decisionToken)-\(showsLeaveDialog)") { await runSpeedTimer() }
        .onChange(of: model.toastCount) { flashToast() }
        .onChange(of: showsLeaveDialog) { wasShowing, isShowing in
            // Dismissed (Keep playing, or tapping outside): re-arm so time spent looking at the
            // dialog never counts against the Speed timer, and the response clock restarts clean.
            if wasShowing && !isShowing { model.restartDecisionClock() }
        }
        .sensoryFeedback(trigger: model.decisions.count) { _, _ in
            guard preferences.hapticsEnabled, let last = model.decisions.last else { return nil }
            return last.isCorrect ? .success : .error
        }
        .confirmationDialog("Leave this session?", isPresented: $showsLeaveDialog, titleVisibility: .visible) {
            Button("Save partial") { model.finish() }
            Button("Discard", role: .destructive, action: onClose)
            Button("Keep playing", role: .cancel) {}
        }
        .sheet(item: $whyContext) { WhySheet(context: $0) }
    }

    private var topBar: some View {
        HStack(spacing: FeltSpacing.m) {
            CloseButton {
                if model.canSavePartial { showsLeaveDialog = true } else { onClose() }
            }
            Text(model.handLimit.map { "Hand \(model.handNumber) / \($0)" } ?? "Hand \(model.handNumber)")
                .feltText(.label).foregroundStyle(FeltColor.textTertiary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(model.correctCount) / \(model.decisions.count)")
                    .feltText(.stat).foregroundStyle(FeltColor.textPrimary)
                    .accessibilityLabel("Correct")
                    .accessibilityValue("\(model.correctCount) of \(model.decisions.count)")
                Text("Streak \(model.currentStreak)")
                    .feltText(.label).foregroundStyle(FeltColor.textTertiary)
                    .accessibilityLabel("Streak")
                    .accessibilityValue("\(model.currentStreak)")
            }
            if model.handLimit == nil {
                Button("END") {
                    if model.decisions.isEmpty { onClose() } else { model.finish() }
                }
                .feltText(.label).foregroundStyle(FeltColor.textPrimary)
                .frame(minWidth: FeltTapTarget.minimum, minHeight: FeltTapTarget.minimum)
                .accessibilityIdentifier("strategy.end")
            }
        }
    }

    /// The dock, FeedbackCard and outcome share one bottom region, sized to at least a FeedbackCard,
    /// so the player's cards stay put as the phase changes (the card lands over the dock).
    private func bottom(bottomInset: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            FeedbackCard(verdict: .incorrect, headline: "The play is Hit",
                         reason: "You chose Stand on hard 16 vs 10.", onWhy: {}, onNext: {})
                .padding(.horizontal, -FeltSpacing.l)
                .hidden()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            bottomContent(bottomInset: bottomInset)
        }
    }

    @ViewBuilder private func bottomContent(bottomInset: CGFloat) -> some View {
        switch model.phase {
        case .awaitingDecision:
            ActionDock(legal: model.legalActions, hint: model.hint) { model.choose($0) }
                // Home-button phones have no bottom inset: keep the dock off the screen edge.
                .padding(.bottom, bottomInset > 0 ? 0 : FeltSpacing.l)
        case .feedback(let graded):
            let text = StrategyText.feedback(isCorrect: graded.isCorrect, chosen: graded.chosen,
                                             correct: graded.correctAction,
                                             label: StrategyText.handLabel(graded.why))
            FeedbackCard(verdict: graded.isCorrect ? .correct : .incorrect, headline: text.headline,
                         reason: text.reason, onWhy: { whyContext = graded.why }, onNext: { model.next() })
                .padding(.horizontal, -FeltSpacing.l)
        case .outcome:
            VStack(spacing: FeltSpacing.m) {
                ForEach(model.outcomeLines, id: \.self) { line in
                    Text(line).feltText(.title).foregroundStyle(FeltColor.textPrimary)
                }
                PrimaryButton(title: "DEAL") { model.deal() }
                    .accessibilityIdentifier("strategy.deal")
            }
            .padding(.bottom, FeltSpacing.l)
        case .summary:
            EmptyView()
        }
    }

    private func runSpeedTimer() async {
        guard model.setup.mode.isTimed, model.phase == .awaitingDecision, !showsLeaveDialog else { return }
        let token = model.decisionToken
        try? await Task.sleep(for: .seconds(model.speedTimerSeconds))
        guard !Task.isCancelled else { return }
        model.timeoutElapsed(token: token)
    }

    private func flashToast() {
        withAnimation(FeltMotion.ui) { showsToast = true }
        AccessibilityNotification.Announcement("Correct").post()
        Task {
            try? await Task.sleep(for: .seconds(FeltToast.displayDuration))
            withAnimation(FeltMotion.ui) { showsToast = false }
        }
    }
}
