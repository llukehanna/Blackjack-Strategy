import SwiftUI
import BJSCore

/// Settings tab: table rules, preferences, reset progress, about.
struct SettingsView: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(PreferencesStore.self) private var preferences
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var model = SettingsViewModel()
    @State private var confirmingReset = false

    var body: some View {
        @Bindable var preferences = preferences
        NavigationStack {
            ZStack {
                FeltBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                        // Leading-aligned and capped to the scroll view's width: a row whose
                        // accessory refuses to shrink (see SettingsRow) must not widen and
                        // center/clip this whole column.
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
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        // See RulesForm's "Max split hands" for why `.fixedSize()` is conditional.
        let stacksVertically = FeltAdaptiveLayout.stacksVertically(dynamicTypeSize)
        return SettingsSection(title: "Preferences") {
            SettingsRow(label: "Speed timer") {
                Stepper(value: $preferences.speedTimerSeconds, in: PreferencesStore.speedTimerRange,
                        step: PreferencesStore.speedTimerStep) {
                    Text(PreferenceLabels.speedTimer(preferences.speedTimerSeconds)).feltText(.body)
                }
                .fixedSize(horizontal: !stacksVertically, vertical: true)
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
                .fixedSize(horizontal: !stacksVertically, vertical: true)
                .accessibilityLabel("Shoe Sim count check")
            }
            SettingsRow(label: "Haptics") {
                Toggle("Haptics", isOn: $preferences.hapticsEnabled).labelsHidden()
            }
        }
    }

    private var aboutSection: some View {
        // See RulesForm's "Max split hands" for why this is conditional: unconditionally, this
        // Text would be just as flexible as SettingsRow's own Spacer at default size, and the two
        // would split the row's slack instead of the Text hugging the trailing edge like every
        // other row's accessory.
        let stacksVertically = FeltAdaptiveLayout.stacksVertically(dynamicTypeSize)
        return SettingsSection(title: "About") {
            SettingsRow(label: "Version") { Text(Self.versionText).feltText(.body) }
            SettingsRow(label: "Strategy") {
                // A plain `Link` sizes to its label's natural width regardless of what's
                // proposed (it won't wrap or scale down), which at accessibility sizes can push
                // this whole screen wider than the device and clip every row. A `Button` with a
                // `Text` label participates in normal SwiftUI layout instead, so it wraps/scales
                // like every other row's content (see ActionDock for the same pattern).
                Button {
                    openURL(URL(string: "https://wizardofodds.com/games/blackjack/strategy/calculator/")!)
                } label: {
                    Text("WizardOfOdds.com")
                        .feltText(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: stacksVertically ? .infinity : nil, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityRemoveTraits(.isButton)
                .accessibilityAddTraits(.isLink)
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
