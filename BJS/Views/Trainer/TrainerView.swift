import SwiftUI
import SwiftData
import BJSCore

struct TrainerView: View {
    @State private var viewModel: TrainerViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(RulesViewModel.self) private var rulesVM
    @Environment(\.dismiss) private var dismiss
    @State private var showRuleConfig = false
    @State private var showEndSessionAlert = false

    private let mode: TrainingMode

    init(mode: TrainingMode, rules: BlackjackRules) {
        self.mode = mode
        let vm = TrainerViewModel(rules: rules)
        vm.mode = mode
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        VStack(spacing: 0) {
            StatsBarView(stats: viewModel.sessionStats)

            if viewModel.phase == .sessionSummary {
                SessionSummaryView(
                    stats: viewModel.sessionStats,
                    mistakes: viewModel.mistakes,
                    onPlayAgain: {
                        viewModel.startNewSession()
                        dismiss()
                    },
                    onHome: {
                        dismiss()
                    }
                )
            } else {
                playArea
            }
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.phase != .sessionSummary)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showRuleConfig = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showRuleConfig) {
            RuleConfigView()
        }
        .onChange(of: showRuleConfig) { _, isShowing in
            if !isShowing {
                viewModel.updateRules(rulesVM.rules)
            }
        }
        .alert("End Session?", isPresented: $showEndSessionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End", role: .destructive) {
                viewModel.endSession(modelContext: modelContext)
            }
        } message: {
            Text("Your progress for this session will be saved.")
        }
        .onAppear {
            viewModel.dealNewHand()
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            handlePhaseChange(newPhase)
        }
    }

    // MARK: - Play Area

    @ViewBuilder
    private var playArea: some View {
        VStack(spacing: 0) {
            Spacer()

            // Dealer hand
            if let dealerHand = viewModel.dealerHand {
                let faceDownIndices: Set<Int> = shouldRevealDealerHole ? [] : [1]
                HandView(cards: dealerHand.cards, faceDownIndices: faceDownIndices)
            }

            Spacer()
                .frame(height: 24)

            // Player hand + total
            if let playerHand = viewModel.playerHand {
                HandView(cards: playerHand.cards)
                Text("Total: \(playerHand.total)")
                    .font(.subheadline)
                    .padding(.top, 4)
            }

            // Hand result label
            if viewModel.phase == .showingResult, let result = viewModel.handResult {
                Text(result.rawValue)
                    .font(.title2.bold())
                    .padding(.top, 8)
            }

            Spacer()
                .frame(height: 24)

            // Learn mode hint
            if let correctAction = viewModel.correctActionForDisplay {
                Text("Correct play: \(correctAction.rawValue.capitalized)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }

            // Action buttons
            ActionButtonsView(
                availableActions: viewModel.availableActions,
                isEnabled: viewModel.phase == .awaitingDecision,
                onAction: { action in
                    viewModel.playerAction(action)
                }
            )

            // End Session button
            Button("End Session") {
                showEndSessionAlert = true
            }
            .padding(.top, 16)
            .padding(.bottom, 24)

            Spacer()
        }
        .overlay {
            if let feedback = viewModel.feedbackState {
                FeedbackOverlayView(feedback: feedback)
                    .animation(.easeIn(duration: 0.15), value: viewModel.feedbackState != nil)
            }
        }
    }

    // MARK: - State

    private var shouldRevealDealerHole: Bool {
        switch viewModel.phase {
        case .playingOut, .showingResult, .sessionSummary:
            return true
        default:
            return false
        }
    }

    // MARK: - Phase Auto-Advance

    private func handlePhaseChange(_ phase: TrainerPhase) {
        switch phase {
        case .showingFeedback:
            Task {
                try? await Task.sleep(for: .seconds(1.0))
                viewModel.advanceFromFeedback()
            }
        case .playingOut:
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                viewModel.playOutDealer()
            }
        case .showingResult:
            Task {
                try? await Task.sleep(for: .seconds(1.0))
                viewModel.advanceToNextHand()
            }
        default:
            break
        }
    }
}
