import BJSCore
import SwiftUI

/// The Strategy trainer table (spec §5): dealer and player hands, the ActionDock, the
/// FeedbackCard after every decision (before the outcome), the outcome, and — once the
/// session ends — the summary. Presented full-screen over the tabs.
struct StrategyTrainerView: View {
    @Bindable private var viewModel: StrategyTrainerViewModel
    private let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isDiscarding = false

    init(viewModel: StrategyTrainerViewModel, onClose: @escaping () -> Void) {
        self._viewModel = Bindable(wrappedValue: viewModel)
        self.onClose = onClose
    }

    var body: some View {
        Group {
            if viewModel.isFinished && !isDiscarding {
                StrategySummaryView(viewModel: viewModel, onDone: onClose)
            } else {
                table
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltBackground()
        .sheet(item: $viewModel.presentedWhy) { context in
            WhySheet(context: context)
        }
        .alert("Leave this session?", isPresented: $viewModel.isConfirmingLeave) {
            Button("Save partial") { viewModel.savePartial() }
            Button("Discard", role: .destructive) {
                isDiscarding = true
                viewModel.discard()
                onClose()
            }
            Button("Keep playing", role: .cancel) { viewModel.keepPlaying() }
        } message: {
            Text("Save the decisions so far and see the summary, or discard this session.")
        }
        .alert("Couldn't save this session", isPresented: $viewModel.isShowingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your summary is shown, but this session won't count toward your progress.")
        }
        .onChange(of: scenePhase) { _, new in
            if new == .active { viewModel.resumeCountdown() }
        }
        .task(id: CountdownTaskID(token: viewModel.countdownToken, phase: scenePhase)) {
            // Speed mode: one countdown per decision. A new token (next decision), a nil
            // token (feedback, prompt) or a scenePhase change (backgrounding, foregrounding)
            // cancels this task before it fires and starts a fresh one, so the countdown
            // never runs — and no timeout is ever recorded — while the app is not active.
            guard let token = viewModel.countdownToken, scenePhase == .active else { return }
            try? await Task.sleep(for: .seconds(viewModel.speedTimerSeconds))
            guard !Task.isCancelled else { return }
            viewModel.timeExpired(token: token)
        }
    }

    /// Identifies one countdown attempt. Either half changing (a new decision, or the app
    /// leaving/returning to the foreground) cancels the running `.task` and starts a clean one.
    private struct CountdownTaskID: Equatable {
        let token: Int?
        let phase: ScenePhase
    }

    // MARK: - Table

    /// Top-anchored: the top bar (and Speed's countdown) sit at the top of the safe area,
    /// the bottom area (dock, FeedbackCard or outcome) at the bottom, and the hands take
    /// whatever is left, shrinking their cards when it is short (iPhone SE, large text).
    /// Nothing is vertically centred, so an over-tall table can never push the top bar
    /// above the screen; if it is still too tall, only the bottom edge can overflow.
    private var table: some View {
        VStack(spacing: FeltSpacing.m) {
            topBar
            if viewModel.config.mode.isTimed {
                countdown
            }
            handsArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Should the smallest cards still not fit (the largest text sizes), they
                // draw under the top bar and the bottom area, never over them.
                .zIndex(-1)
            bottomArea
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.bottom, FeltSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(reduceMotion ? FeltMotion.crossFade(duration: FeltMotion.uiDuration) : FeltMotion.ui,
                   value: viewModel.phase)
    }

    private var topBar: some View {
        HStack(spacing: FeltSpacing.s) {
            Button {
                if viewModel.requestLeave() { onClose() }
            } label: {
                Image(systemName: "xmark")
                    .feltType(.title)
                    .foregroundStyle(FeltColor.textPrimary)
                    .frame(width: FeltMetrics.minTapTarget, height: FeltMetrics.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FeltPressableStyle())
            .accessibilityLabel("Close")
            .accessibilityIdentifier("trainer.close")

            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Text(StrategyText.progress(handNumber: viewModel.handNumber, limit: viewModel.config.length.handLimit))
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("trainer.progress")
                Text(viewModel.config.mode.displayName)
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textTertiary)
            }
            Spacer(minLength: 0)

            if viewModel.config.length == .endless {
                Button("End") { viewModel.endSession() }
                    .feltType(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(FeltColor.textPrimary)
                    .frame(minWidth: FeltMetrics.minTapTarget, minHeight: FeltMetrics.minTapTarget)
                    .buttonStyle(FeltPressableStyle())
                    .accessibilityHint("Ends the session and shows the summary")
                    .accessibilityIdentifier("trainer.end")
            } else {
                Text("\(viewModel.summary.correctDecisions)/\(viewModel.summary.decisionCount)")
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textSecondary)
                    .frame(minWidth: FeltMetrics.minTapTarget, minHeight: FeltMetrics.minTapTarget)
                    .accessibilityLabel("\(viewModel.summary.correctDecisions) of \(viewModel.summary.decisionCount) correct")
                    .accessibilityIdentifier("trainer.score")
            }
        }
    }

    private var countdown: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : nil, paused: viewModel.countdownToken == nil)) { context in
            CountdownBar(fraction: CountdownBar.remainingFraction(startedAt: viewModel.decisionStartedAt,
                                                                   now: context.date,
                                                                   duration: viewModel.speedTimerSeconds))
        }
        .opacity(viewModel.countdownToken == nil ? 0 : 1)
        .accessibilityIdentifier("trainer.countdown")
    }

    // MARK: - Hands

    /// Card widths for the hands. The table uses the largest set whose hands fit the height
    /// left between the top bar and the bottom area.
    private struct CardSizes {
        let dealer: CGFloat
        let player: CGFloat
        let splitPlayer: CGFloat

        static let regular = CardSizes(dealer: 64, player: 72, splitPlayer: 52)
        static let compact = CardSizes(dealer: 52, player: 58, splitPlayer: 44)
        static let tight = CardSizes(dealer: 40, player: 44, splitPlayer: 36)
    }

    private var handsArea: some View {
        ViewThatFits(in: .vertical) {
            hands(.regular)
            hands(.compact)
            hands(.tight)
        }
    }

    private func hands(_ sizes: CardSizes) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            dealerArea(cardWidth: sizes.dealer)
            Spacer(minLength: FeltSpacing.m)
            playerArea(cardWidth: viewModel.playerHands.count > 1 ? sizes.splitPlayer : sizes.player)
            Spacer(minLength: 0)
        }
    }

    private func dealerArea(cardWidth: CGFloat) -> some View {
        VStack(spacing: FeltSpacing.s) {
            Text("Dealer")
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
            HandView(cards: viewModel.dealerHand.cards,
                     faceDownIndices: viewModel.isDealerRevealed ? [] : [1],
                     cardWidth: cardWidth, overlap: 0.35,
                     totalLabel: viewModel.isDealerRevealed ? StrategyText.total(viewModel.dealerHand) : nil)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trainer.dealer")
    }

    private func playerArea(cardWidth: CGFloat) -> some View {
        VStack(spacing: FeltSpacing.s) {
            ViewThatFits(in: .horizontal) {
                playerHands(cardWidth: cardWidth)
                ScrollView(.horizontal, showsIndicators: false) {
                    playerHands(cardWidth: cardWidth)
                }
            }
            Text("You")
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trainer.player")
    }

    /// Split hands, built eagerly in fixed slots rather than with `ForEach`: SwiftUI can call a
    /// ForEach item closure off the main thread while measuring (here under ViewThatFits), which
    /// traps Swift 6's main-actor isolation check. The rules allow at most 4 hands.
    private func playerHands(cardWidth: CGFloat) -> some View {
        let hands = viewModel.playerHands
        return HStack(alignment: .top, spacing: FeltSpacing.l) {
            playerHand(at: 0, of: hands, cardWidth: cardWidth)
            playerHand(at: 1, of: hands, cardWidth: cardWidth)
            playerHand(at: 2, of: hands, cardWidth: cardWidth)
            playerHand(at: 3, of: hands, cardWidth: cardWidth)
        }
    }

    @ViewBuilder
    private func playerHand(at index: Int, of hands: [PlayerHandState], cardWidth: CGFloat) -> some View {
        if index < hands.count {
            let state = hands[index]
            VStack(spacing: FeltSpacing.xs) {
                HandView(cards: state.hand.cards, cardWidth: cardWidth, overlap: 0.35,
                         totalLabel: StrategyText.total(state.hand))
                if viewModel.phase == .outcome {
                    Text(StrategyText.outcome(state))
                        .feltType(.label)
                        .foregroundStyle(FeltColor.textPrimary)
                        .accessibilityIdentifier("trainer.handOutcome.\(index)")
                }
            }
            .opacity(isDimmed(index, handCount: hands.count) ? 0.4 : 1)
        }
    }

    /// With split hands, the hands not being played are dimmed while decisions are made.
    private func isDimmed(_ index: Int, handCount: Int) -> Bool {
        handCount > 1 && index != viewModel.activeHandIndex
            && (viewModel.phase == .decision || viewModel.phase == .feedback)
    }

    // MARK: - Bottom: dock + feedback, or the outcome

    @ViewBuilder
    private var bottomArea: some View {
        switch viewModel.phase {
        case .decision, .feedback:
            // The FeedbackCard sits over the dock, bottom-anchored. It is part of the layout
            // (not an overlay), so its height, badge included, is taken from the hands'
            // space: the card never covers the player's cards or total, and never pushes
            // the table past the screen.
            ZStack(alignment: .bottom) {
                ActionDock(allowed: viewModel.allowedActions, hint: viewModel.hint) { action in
                    viewModel.choose(action)
                }
                if let decision = viewModel.feedback {
                    FeedbackCard(isCorrect: decision.isCorrect,
                                 headline: DecisionFeedback.headline(for: decision),
                                 reason: DecisionFeedback.reason(for: decision),
                                 onWhy: { viewModel.showWhy(for: decision) },
                                 onNext: { viewModel.next() })
                        .padding(.top, FeedbackCard.badgeSize / 2)
                        .transition(FeltMotion.panelTransition(reduceMotion: reduceMotion))
                }
            }
        case .outcome:
            VStack(spacing: FeltSpacing.m) {
                Text(StrategyText.dealerResult(viewModel.dealerHand))
                    .feltType(.title)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("trainer.outcome")
                PrimaryButton(viewModel.session.isLastHand ? "See summary" : "Next hand") {
                    viewModel.nextHand()
                }
                .accessibilityIdentifier("trainer.nextHand")
            }
            .transition(FeltMotion.panelTransition(reduceMotion: reduceMotion))
        case .finished:
            EmptyView()
        }
    }
}
