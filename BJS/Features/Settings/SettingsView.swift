import SwiftUI
import BJSCore

/// Settings tab: table rules, preferences, reset progress, about.
struct SettingsView: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(PreferencesStore.self) private var preferences
    @Environment(SessionStore.self) private var sessionStore
    @State private var model = SettingsViewModel()
    @State private var confirmingReset = false

    var body: some View {
        @Bindable var preferences = preferences
        NavigationStack {
            ZStack {
                FeltBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                        Text("Settings")
                            .feltText(.display)
                            .foregroundStyle(FeltColor.textPrimary)
                        RulesForm(rules: Binding(get: { rulesStore.rules }, set: { rulesStore.rules = $0 }))
                        preferencesSection(preferences)
                        SettingsSection(title: "Progress") {
                            SettingsRow(label: "Reset progress") {
                                Button("Reset", role: .destructive) { confirmingReset = true }
                                    .foregroundStyle(FeltColor.incorrect)
                                    .font(FeltType.title.font)
                                    .frame(minHeight: FeltTapTarget.minimum)
                                    .contentShape(Rectangle())
                            }
                        }
                        aboutSection
                        #if DEBUG
                        SettingsSection(title: "Debug") {
                            NavigationLink {
                                FeltCatalogue().toolbar(.visible, for: .navigationBar)
                            } label: {
                                SettingsRow(label: "Felt catalogue") { Image(systemName: "chevron.right") }
                            }
                            .buttonStyle(.plain)
                        }
                        #endif
                    }
                    .padding(FeltSpacing.l)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .confirmationDialog("Reset all progress?", isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Reset progress", role: .destructive) { model.resetProgress(using: sessionStore) }
        } message: {
            Text("This deletes every saved session. Your rules and preferences stay.")
        }
        .alert("Couldn't reset progress", isPresented: $model.showsResetError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Nothing was deleted. Please try again.")
        }
    }

    private func preferencesSection(_ preferences: PreferencesStore) -> some View {
        @Bindable var preferences = preferences
        return SettingsSection(title: "Preferences") {
            SettingsRow(label: "Speed timer") {
                Stepper(value: $preferences.speedTimerSeconds, in: PreferencesStore.speedTimerRange,
                        step: PreferencesStore.speedTimerStep) {
                    Text(PreferenceLabels.speedTimer(preferences.speedTimerSeconds)).feltText(.body)
                }
                .fixedSize()
                .accessibilityLabel("Speed timer")
            }
            SettingsRow(label: "True count") {
                Picker("True count", selection: $preferences.trueCountConvention) {
                    ForEach(TrueCountConvention.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            SettingsRow(label: "Shoe Sim count check") {
                Stepper(value: $preferences.shoeCheckFrequency, in: PreferencesStore.shoeCheckRange) {
                    Text(PreferenceLabels.shoeCheck(preferences.shoeCheckFrequency)).feltText(.body)
                }
                .fixedSize()
                .accessibilityLabel("Shoe Sim count check")
            }
            SettingsRow(label: "Haptics") {
                Toggle("Haptics", isOn: $preferences.hapticsEnabled).labelsHidden()
            }
        }
    }

    private var aboutSection: some View {
        SettingsSection(title: "About") {
            SettingsRow(label: "Version") { Text(Self.versionText).feltText(.body) }
            SettingsRow(label: "Strategy") {
                Link("WizardOfOdds.com",
                     destination: URL(string: "https://wizardofodds.com/games/blackjack/strategy/calculator/")!)
                    .feltText(.body)
            }
        }
    }

    private static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
