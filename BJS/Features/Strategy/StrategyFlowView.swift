import os
import SwiftUI
import BJSCore

/// Setup → trainer → summary for one full-screen Strategy launch.
struct StrategyFlowView: View {
    /// Non-nil (Continue): start the trainer straight away with this setup.
    let initialSetup: StrategySetup?
    var handLimitOverride: Int? = nil
    var seed: UInt64? = nil
    let onClose: () -> Void

    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(PreferencesStore.self) private var preferences
    @Environment(SessionStore.self) private var sessionStore
    @State private var setup = StrategySetup()
    @State private var trainer: StrategyTrainerViewModel?
    @State private var weights: [TrainingCell: Double]?
    @State private var didAutoStart = false

    private let logger = Logger(subsystem: "com.bjs.app", category: "StrategyFlow")

    var body: some View {
        ZStack {
            FeltBackground()
            if let trainer {
                StrategyTrainerView(model: trainer, onClose: onClose, onAgain: { start(trainer.setup) })
                    .id(trainer.sessionID)
            } else {
                StrategySetupView(setup: $setup, weakSpotsReady: weights != nil,
                                  onStart: { start(setup) }, onClose: onClose)
            }
        }
        .task(id: sessionStore.revision) { loadWeights() }
        .task {
            guard let initialSetup, !didAutoStart else { return }
            didAutoStart = true
            setup = initialSetup
            loadWeights()
            start(initialSetup)
        }
    }

    private func loadWeights() {
        do {
            weights = WeakSpotWeights.compute(from: try sessionStore.decisionSamples(modules: [.strategy, .shoe]))
        } catch {
            logger.error("Weak-spot history failed to load: \(error.localizedDescription)")
            weights = nil
        }
    }

    private func start(_ setup: StrategySetup) {
        do {
            preferences.lastLaunch = try setup.lastLaunch()
        } catch {
            logger.error("lastLaunch failed to encode: \(error.localizedDescription)")
        }
        let store = sessionStore
        trainer = StrategyTrainerViewModel(
            setup: setup, rules: rulesStore.rules, weights: weights,
            speedTimerSeconds: preferences.speedTimerSeconds, handLimitOverride: handLimitOverride,
            seed: seed ?? UInt64.random(in: .min ... .max),
            persist: { try store.save($0) })
    }
}
