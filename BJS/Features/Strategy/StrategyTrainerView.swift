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
            VStack(spacing: FeltSpacing.l) {
                topBar
                if model.setup.mode.isTimed && model.phase == .awaitingDecision {
                    CountdownBar(startedAt: model.decisionStartedAt, duration: model.speedTimerSeconds)
                }
                DealerHandView(cards: model.dealerCards, isRevealed: model.isDealerRevealed,
                               total: model.isDealerRevealed ? model.round?.dealer.total : nil,
                               cardWidth: SplitHandsLayout.maxCardWidth)
                Spacer(minLength: 0)
                SplitHandsView(hands: model.playerHands.map { $0.hand.cards },
                               totals: model.playerHands.map { "\($0.hand.total)" },
                               activeIndex: model.phase == .awaitingDecision ? model.activeHandIndex : nil,
                               availableWidth: geo.size.width - 2 * FeltSpacing.l)
                Spacer(minLength: 0)
                bottom
            }
            .padding(.horizontal, FeltSpacing.l)
            .overlay(alignment: .top) {
                if showsToast {
                    FeltToast(text: "Correct").padding(.top, 56).transition(.opacity)
                }
            }
        }
        .task(id: model.decisionToken) { await runSpeedTimer() }
        .onChange(of: model.toastCount) { flashToast() }
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
            Text("\(model.correctCount) / \(model.decisions.count)")
                .feltText(.stat).foregroundStyle(FeltColor.textPrimary)
                .accessibilityLabel("Correct")
                .accessibilityValue("\(model.correctCount) of \(model.decisions.count)")
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

    @ViewBuilder private var bottom: some View {
        switch model.phase {
        case .awaitingDecision:
            ActionDock(legal: model.legalActions, hint: model.hint) { model.choose($0) }
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
        guard model.setup.mode.isTimed, model.phase == .awaitingDecision else { return }
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
