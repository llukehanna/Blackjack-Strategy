import os
import SwiftUI
import BJSCore

enum CountingScreen: Equatable {
    /// Continue: blank until the saved drill starts, so the menu doesn't flash.
    case launching
    case menu
    case runningSetup
    case trueSetup
    case cardValues
    case running
    case trueCount
}

/// Menu → setup → drill → summary for one full-screen Counting launch (Step 4 spec §2).
struct CountingFlowView: View {
    /// Non-nil (Continue): start that drill straight away.
    let initialSetup: CountingSetup?
    var paceOverride: Double? = nil
    var seed: UInt64? = nil
    let onClose: () -> Void

    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(PreferencesStore.self) private var preferences
    @Environment(SessionStore.self) private var sessionStore
    @State private var screen: CountingScreen
    @State private var runningSetup = RunningCountSetup()
    @State private var trueSetup = TrueCountSetup()
    @State private var running: RunningCountDrillViewModel?
    @State private var trueCount: TrueCountDrillViewModel?
    @State private var cardValues: CardValuesViewModel?
    @State private var didAutoStart = false

    private let logger = Logger(subsystem: "com.bjs.app", category: "CountingFlow")

    init(initialSetup: CountingSetup?, paceOverride: Double? = nil, seed: UInt64? = nil,
         onClose: @escaping () -> Void) {
        self.initialSetup = initialSetup
        self.paceOverride = paceOverride
        self.seed = seed
        self.onClose = onClose
        _screen = State(initialValue: initialSetup == nil ? .menu : .launching)
    }

    var body: some View {
        ZStack {
            FeltBackground()
            content
        }
        .task {
            guard let initialSetup, !didAutoStart else { return }
            didAutoStart = true
            switch initialSetup {
            case .runningCount(let setup):
                runningSetup = setup
                startRunning(setup)
            case .trueCount(let setup):
                trueSetup = setup
                startTrueCount(setup)
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case .launching:
            EmptyView()
        case .menu:
            CountingMenuView(onSelect: open, onClose: onClose)
        case .runningSetup:
            RunningCountSetupView(setup: $runningSetup, onStart: { startRunning(runningSetup) },
                                  onBack: { screen = .menu })
        case .trueSetup:
            TrueCountSetupView(setup: $trueSetup, convention: preferences.trueCountConvention,
                               deckCount: rulesStore.rules.deckCount,
                               onStart: { startTrueCount(trueSetup) }, onBack: { screen = .menu })
        case .cardValues:
            if let cardValues {
                CardValuesView(model: cardValues, onBack: { screen = .menu })
            }
        case .running:
            if let running {
                RunningCountDrillView(model: running, onClose: onClose, onAgain: { startRunning(running.setup) })
                    .id(running.sessionID)
            }
        case .trueCount:
            if let trueCount {
                TrueCountDrillView(model: trueCount, onClose: onClose, onAgain: { startTrueCount(trueCount.setup) })
                    .id(trueCount.sessionID)
            }
        }
    }

    private func open(_ next: CountingScreen) {
        if next == .cardValues {
            cardValues = CardValuesViewModel(seed: seed ?? UInt64.random(in: .min ... .max))
        }
        screen = next
    }

    private func startRunning(_ setup: RunningCountSetup) {
        remember(.runningCount(setup))
        let store = sessionStore
        running = RunningCountDrillViewModel(
            setup: setup, rules: rulesStore.rules, paceOverride: paceOverride,
            seed: seed ?? UInt64.random(in: .min ... .max), persist: { try store.save($0) })
        screen = .running
    }

    private func startTrueCount(_ setup: TrueCountSetup) {
        remember(.trueCount(setup))
        let store = sessionStore
        trueCount = TrueCountDrillViewModel(
            setup: setup, rules: rulesStore.rules, convention: preferences.trueCountConvention,
            seed: seed ?? UInt64.random(in: .min ... .max), persist: { try store.save($0) })
        screen = .trueCount
    }

    private func remember(_ setup: CountingSetup) {
        do {
            preferences.lastLaunch = try setup.lastLaunch()
        } catch {
            logger.error("lastLaunch failed to encode: \(error.localizedDescription)")
        }
    }
}
