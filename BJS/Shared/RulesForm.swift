import SwiftUI
import BJSCore

/// Preset picker plus every `BlackjackRules` field. Shared so Edge (Step 5) can edit rules
/// other than the active set without importing Settings.
struct RulesForm: View {
    @Binding var rules: BlackjackRules

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    static func surrenderFootnote(for rules: BlackjackRules) -> String? {
        rules.peekRule == .europeanNoPeek
            ? "With no hole card, late and early surrender play the same."
            : nil
    }

    var body: some View {
        // `.fixedSize()` below keeps the Stepper compact at default sizes; at accessibility sizes
        // it must accept the row's proposed (narrower) width instead, or it reports its own,
        // wider-than-proposed, ideal width and can overflow the screen.
        let stacksVertically = FeltAdaptiveLayout.stacksVertically(dynamicTypeSize)
        VStack(spacing: FeltSpacing.xl) {
            SettingsSection(title: "Preset") {
                SettingsRow(label: "Rule set") {
                    Menu {
                        ForEach(RulePreset.allCases) { preset in
                            Button(preset.displayName) { rules = preset.rules }
                        }
                    } label: {
                        HStack(spacing: FeltSpacing.xs) {
                            Text(RulePreset.label(for: rules))
                            Image(systemName: "chevron.up.chevron.down").font(.caption)
                        }
                        .feltText(.body)
                        .frame(minHeight: FeltTapTarget.minimum)
                    }
                    .accessibilityIdentifier("settings.preset")
                }
            }
            SettingsSection(title: "Table rules") {
                SettingsRow(label: "Decks") {
                    picker("Decks", $rules.deckCount, BlackjackRules.DeckCount.allCases) { $0.label }
                }
                SettingsRow(label: "Dealer soft 17") {
                    picker("Dealer soft 17", $rules.dealerSoft17, BlackjackRules.DealerSoft17.allCases) { $0.label }
                }
                SettingsRow(label: "Blackjack pays") {
                    picker("Blackjack pays", $rules.blackjackPayout,
                           BlackjackRules.BlackjackPayout.allCases) { $0.label }
                }
                SettingsRow(label: "Double on") {
                    picker("Double on", $rules.doubleRestriction,
                           BlackjackRules.DoubleRestriction.allCases) { $0.label }
                }
                SettingsRow(label: "Double after split") {
                    Toggle("Double after split", isOn: $rules.doubleAfterSplit).labelsHidden()
                }
                SettingsRow(label: "Max split hands") {
                    Stepper(value: $rules.maxSplitHands, in: ActiveRulesStore.maxSplitHandsRange) {
                        Text("\(rules.maxSplitHands)").feltText(.body)
                    }
                    .fixedSize(horizontal: !stacksVertically, vertical: true)
                    .accessibilityLabel("Max split hands")
                }
                SettingsRow(label: "Resplit aces") {
                    Toggle("Resplit aces", isOn: $rules.resplitAces).labelsHidden()
                }
                SettingsRow(label: "Hit split aces") {
                    Toggle("Hit split aces", isOn: $rules.hitSplitAces).labelsHidden()
                }
                SettingsRow(label: "Surrender", footnote: Self.surrenderFootnote(for: rules)) {
                    picker("Surrender", $rules.surrenderRule, BlackjackRules.SurrenderRule.allCases) { $0.label }
                }
                SettingsRow(label: "Hole card") {
                    picker("Hole card", $rules.peekRule, BlackjackRules.PeekRule.allCases) { $0.label }
                }
            }
        }
    }

    private func picker<Value: Hashable>(_ title: String, _ selection: Binding<Value>, _ options: [Value],
                                         label: @escaping (Value) -> String) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { Text(label($0)).tag($0) }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
}
