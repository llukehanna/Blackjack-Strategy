import BJSCore
import SwiftData
import SwiftUI

/// One full-screen Strategy session (spec §5: sessions are presented full-screen over the tabs).
///
/// On appear it snapshots the active rules and the Speed timer, loads decision history for
/// Weak-spots mode, and builds the ViewModel with a SwiftData saver.
struct StrategySessionScreen: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(Preferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StrategyTrainerViewModel?

    private let config: StrategySessionConfig
    private let seed: UInt64?
    private let onClose: () -> Void

    /// - Parameter seed: a fixed seed (UI tests), or nil for a random one.
    init(config: StrategySessionConfig, seed: UInt64?, onClose: @escaping () -> Void) {
        self.config = config
        self.seed = seed
        self.onClose = onClose
    }

    var body: some View {
        Group {
            if let viewModel {
                StrategyTrainerView(viewModel: viewModel, onClose: onClose)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltBackground()
        .onAppear(perform: startIfNeeded)
    }

    private func startIfNeeded() {
        guard viewModel == nil else { return }
        let history = config.mode.usesWeakSpotWeights ? DecisionHistory.recentSamples(in: modelContext) : []
        viewModel = StrategyTrainerViewModel(config: config, rules: rulesStore.rules,
                                             speedTimerSeconds: preferences.speedTimerSeconds,
                                             history: history,
                                             seed: seed ?? UInt64.random(in: UInt64.min...UInt64.max),
                                             saver: SwiftDataStrategySessionSaver(context: modelContext))
    }
}
