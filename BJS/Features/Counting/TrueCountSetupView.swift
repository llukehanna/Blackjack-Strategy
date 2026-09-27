import SwiftUI
import BJSCore

struct TrueCountSetupView: View {
    @Binding var setup: TrueCountSetup
    let convention: TrueCountConvention
    let deckCount: BlackjackRules.DeckCount
    let onStart: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                CountingHeader(title: "True count", onBack: onBack)
                VStack(alignment: .leading, spacing: FeltSpacing.s) {
                    Text("Questions").feltText(.label).foregroundStyle(FeltColor.textTertiary)
                    ModePicker(options: TrueCountLength.options, selection: $setup.length) { $0.title }
                }
                SettingsSection(title: "Grading") {
                    SettingsRow(label: "Rounding",
                                footnote: "\(CountingText.conventionRule(convention)) Change it in Settings.") {
                        Text(convention.label)
                    }
                    SettingsRow(label: "Shoe") { Text(deckCount.label) }
                }
                PrimaryButton(title: "Start", action: onStart)
                    .accessibilityIdentifier("counting.start")
            }
            .padding(FeltSpacing.l)
        }
    }
}
