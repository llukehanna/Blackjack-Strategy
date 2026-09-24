import BJSCore
import SwiftData
import SwiftUI

/// Settings tab (spec §5): table rules (presets first, then every `BlackjackRules` field),
/// preferences, and Reset progress with a confirmation.
struct SettingsView: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(Preferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext
    @State private var isConfirmingReset = false
    @State private var resetFailed = false

    init() {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                Text("Settings")
                    .feltType(.display)
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("settings.title")
                rulesSection
                preferencesSection
                progressSection
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.xl)
        }
        .accessibilityIdentifier("settings.scroll")
        .feltBackground()
        .alert("Reset progress?", isPresented: $isConfirmingReset) {
            Button("Delete all progress", role: .destructive, action: resetProgress)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes every saved session. Your rules and preferences stay.")
        }
        .alert("Couldn't reset progress", isPresented: $resetFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your progress was not changed. Please try again.")
        }
    }

    // MARK: - Table rules

    private var presetSelection: Binding<RulePreset?> {
        let store = rulesStore
        return Binding(
            get: { store.matchingPreset },
            set: { preset in
                if let preset { store.apply(preset) }
            }
        )
    }

    /// Every preset, plus "Custom" while the rules match none of them.
    private var presetOptions: [RulePreset?] {
        SettingsPresetOptions.options(matching: rulesStore.matchingPreset)
    }

    private var rulesSection: some View {
        @Bindable var store = rulesStore
        return SettingsSection("Table rules") {
            SettingsRow("Preset", selection: presetSelection, options: presetOptions,
                        optionTitle: RulesSummary.presetName)
            SettingsRow("Decks", selection: $store.rules.deckCount,
                        options: BlackjackRules.DeckCount.allCases) { $0.displayName }
            SettingsRow("Dealer soft 17", selection: $store.rules.dealerSoft17,
                        options: BlackjackRules.DealerSoft17.allCases) { $0.displayName }
            SettingsRow("Blackjack pays", selection: $store.rules.blackjackPayout,
                        options: BlackjackRules.BlackjackPayout.allCases) { $0.displayName }
            SettingsRow("Double on", selection: $store.rules.doubleRestriction,
                        options: BlackjackRules.DoubleRestriction.allCases) { $0.displayName }
            SettingsRow("Double after split", isOn: $store.rules.doubleAfterSplit)
            SettingsRow("Max split hands", selection: $store.rules.maxSplitHands,
                        options: [2, 3, 4]) { "\($0)" }
            SettingsRow("Resplit aces", isOn: $store.rules.resplitAces)
            SettingsRow("Hit split aces", isOn: $store.rules.hitSplitAces)
            SettingsRow("Surrender", selection: $store.rules.surrenderRule,
                        options: BlackjackRules.SurrenderRule.allCases) { $0.displayName }
            SettingsRow("Dealer hole card", selection: $store.rules.peekRule,
                        options: BlackjackRules.PeekRule.allCases, showsSeparator: false) { $0.displayName }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        @Bindable var prefs = preferences
        return SettingsSection("Preferences") {
            SettingsRow("Speed-mode timer", selection: $prefs.speedTimerSeconds,
                        options: Preferences.speedTimerOptions) { String(format: "%.1f s", $0) }
            SettingsRow("True count", selection: $prefs.trueCountConvention,
                        options: TrueCountConvention.allCases) { $0.displayName }
            SettingsRow("Shoe Sim count check", selection: $prefs.shoeCheckEveryRounds,
                        options: Preferences.shoeCheckOptions) { "1 in \($0) rounds" }
            SettingsRow("Haptics", isOn: $prefs.hapticsEnabled, showsSeparator: false)
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        SettingsSection("Progress") {
            Button {
                isConfirmingReset = true
            } label: {
                Text("Reset progress")
                    .feltType(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(FeltColor.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget, alignment: .leading)
                    .padding(.horizontal, FeltSpacing.l)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FeltPressableStyle())
            .accessibilityHint("Deletes all saved sessions after you confirm")
            .accessibilityIdentifier("settings.resetProgress")
        }
    }

    private func resetProgress() {
        do {
            try ProgressReset.deleteAllProgress(in: modelContext)
        } catch {
            let message = String(describing: error)
            AppLog.persistence.error("Reset progress failed: \(message, privacy: .public)")
            resetFailed = true
        }
    }
}
