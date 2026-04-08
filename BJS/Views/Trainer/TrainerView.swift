import SwiftUI
import SwiftData
import BJSCore

/// TrainerView — visual contract for the whole app per UI-SPEC 07.
/// Delete-and-rewrite against the layout contract: nav chrome, dealer hand, watermark,
/// player hand, table-edge arcs, two-row action dock, bottom-card feedback overlay.
/// No StatsBar, no hand-total numerics, no DEALER/YOU labels. TrainerViewModel is unchanged.
struct TrainerView: View {
    @State private var viewModel: TrainerViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(RulesViewModel.self) private var rulesVM
    @Environment(\.dismiss) private var dismiss
    @State private var showEndSessionConfirm = false
    @State private var playingOutTask: Task<Void, Never>?
    @State private var showingResultTask: Task<Void, Never>?
    @State private var whyContext: WhyContext?

    private let mode: TrainingMode

    init(mode: TrainingMode, rules: BlackjackRules) {
        self.mode = mode
        let vm = TrainerViewModel(rules: rules)
        vm.mode = mode
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            BJSColors.surfaceBase.ignoresSafeArea()

            if viewModel.phase == .sessionSummary {
                SessionSummaryView(
                    stats: viewModel.sessionStats,
                    mistakes: viewModel.mistakes,
                    onPlayAgain: {
                        viewModel.startNewSession()
                        dismiss()
                    },
                    onHome: { dismiss() }
                )
            } else {
                mainStack
            }

            if let feedback = viewModel.feedbackState, viewModel.phase != .sessionSummary {
                FeedbackOverlayView(
                    isCorrect: feedback.isCorrect,
                    userActionLabel: userActionLabel(from: feedback),
                    correctActionLabel: correctActionLabel(from: feedback),
                    onDeal: { viewModel.advanceFromFeedback() },
                    onWhy: { whyContext = viewModel.makeWhyContext() }
                )
                .animation(AnimationTiming.overlayIn, value: viewModel.feedbackState != nil)
            }
        }
        .sheet(item: $whyContext) { ctx in
            WhyExplanationView(context: ctx)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert("End this session?", isPresented: $showEndSessionConfirm) {
            Button("End Session", role: .destructive) {
                viewModel.endSession(modelContext: modelContext)
            }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("Your session results so far will be saved.")
        }
        .onAppear { viewModel.dealNewHand() }
        .onChange(of: viewModel.phase) { _, newPhase in
            handlePhaseChange(newPhase)
        }
    }

    // MARK: - Main Stack

    @ViewBuilder
    private var mainStack: some View {
        VStack(spacing: 0) {
            navChrome

            Spacer().frame(height: Spacing.xxl)

            // Dealer hand
            if let dealerHand = viewModel.dealerHand {
                let faceDownIndices: Set<Int> = shouldRevealDealerHole ? [] : [1]
                HandView(cards: dealerHand.cards, faceDownIndices: faceDownIndices, overlap: .dealer)
            }

            Spacer().frame(height: Spacing.xl)

            // Brand watermark
            Text("BJS")
                .font(Typography.caption)
                .tracking(3)
                .foregroundStyle(BJSColors.watermarkInk.opacity(0.25))

            Spacer().frame(height: Spacing.xl)

            // Player hand (no total label, no player-side caption per UI-07-D10)
            if let playerHand = viewModel.playerHand {
                HandView(cards: playerHand.cards, overlap: .player)
            }

            Spacer(minLength: 0)

            // Table-edge arcs
            TableEdgeArcs()
                .frame(height: 60)

            // Action dock — hidden behind feedback overlay when feedback shown
            if viewModel.feedbackState == nil {
                ActionButtonsView(
                    canSplit: viewModel.availableActions.contains(.split),
                    canDouble: viewModel.availableActions.contains(.double),
                    canSurrender: viewModel.availableActions.contains(.surrender),
                    isEnabled: viewModel.phase == .awaitingDecision,
                    onStand: { viewModel.playerAction(.stand) },
                    onHit: { viewModel.playerAction(.hit) },
                    onSplit: { viewModel.playerAction(.split) },
                    onDouble: { viewModel.playerAction(.double) },
                    onSurrender: { viewModel.playerAction(.surrender) }
                )
            }
        }
    }

    // MARK: - Nav Chrome

    @ViewBuilder
    private var navChrome: some View {
        HStack {
            Button(action: { showEndSessionConfirm = true }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BJSColors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(BJSColors.surfaceRaised))
            }
            Spacer()
            Button(action: { /* SOS placeholder — UI-07-D9 */ }) {
                Text("SOS")
                    .font(Typography.caption)
                    .tracking(1.5)
                    .foregroundStyle(BJSColors.actionLabel)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: 44)
    }

    // MARK: - Derived state

    private var shouldRevealDealerHole: Bool {
        switch viewModel.phase {
        case .playingOut, .showingResult, .sessionSummary:
            return true
        default:
            return false
        }
    }

    private func userActionLabel(from feedback: FeedbackResult) -> String {
        let action = viewModel.decisions.last?.playerAction
        return Self.label(for: action)
    }

    private func correctActionLabel(from feedback: FeedbackResult) -> String {
        switch feedback {
        case .incorrect(let correctAction):
            return Self.label(for: correctAction)
        case .correct:
            return Self.label(for: viewModel.decisions.last?.correctAction)
        }
    }

    static func label(for action: Action?) -> String {
        guard let action = action else { return "" }
        switch action {
        case .stand: return "STAND"
        case .hit: return "HIT"
        case .split: return "SPLIT"
        case .double: return "DOUBLE"
        case .surrender: return "SURREN."
        }
    }

    // MARK: - Phase Auto-Advance
    // Feedback is now user-advanced via the DEAL button in FeedbackOverlayView.
    // playingOut / showingResult still auto-advance on short timers.

    private func handlePhaseChange(_ phase: TrainerPhase) {
        // Always cancel any pending phase-transition tasks to prevent stale
        // closures from mutating state during a later phase (UAT test 12).
        playingOutTask?.cancel()
        playingOutTask = nil
        showingResultTask?.cancel()
        showingResultTask = nil

        switch phase {
        case .playingOut:
            playingOutTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.3))
                guard !Task.isCancelled else { return }
                guard viewModel.phase == .playingOut else { return }
                viewModel.playOutDealer()
            }
        case .showingResult:
            showingResultTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                guard viewModel.phase == .showingResult else { return }
                viewModel.advanceToNextHand()
            }
        default:
            break
        }
    }
}

// MARK: - Table Edge Arcs

/// Two thin gold arcs suggesting the felt edge of a blackjack table.
/// Geometry is approximate per UI-SPEC (observed: false — inferred from reference).
private struct TableEdgeArcs: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Ellipse()
                    .stroke(BJSColors.accentGold.opacity(0.8), lineWidth: 1)
                    .frame(width: geo.size.width * 1.8, height: geo.size.height * 3)
                    .offset(y: geo.size.height * 1.2)
                Ellipse()
                    .stroke(BJSColors.accentGold.opacity(0.5), lineWidth: 1)
                    .frame(width: geo.size.width * 2.1, height: geo.size.height * 3.4)
                    .offset(y: geo.size.height * 1.4)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("Pre-decision") {
    NavigationStack {
        TrainerView(mode: .test, rules: BlackjackRules())
            .environment(RulesViewModel())
    }
}

#Preview("Feedback — Incorrect") {
    NavigationStack {
        TrainerView(mode: .test, rules: BlackjackRules())
            .environment(RulesViewModel())
    }
}
