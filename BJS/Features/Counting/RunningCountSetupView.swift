import SwiftUI

struct RunningCountSetupView: View {
    @Binding var setup: RunningCountSetup
    let onStart: () -> Void
    let onBack: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                CountingHeader(title: "Running count", onBack: onBack)
                group("Cards at a time") {
                    ModePicker(options: RunningCountSetup.groupSizes, selection: $setup.groupSize) { "\($0)" }
                }
                group("Cards") {
                    ModePicker(options: RunningCountLength.options, selection: $setup.length) { $0.title }
                }
                SettingsSection(title: "Pace and checks") {
                    SettingsRow(label: "Per group", footnote: "Lower is faster.") {
                        Stepper(value: $setup.paceTenths, in: RunningCountSetup.paceTenthsRange) {
                            Text(CountingText.pace(setup.pace)).feltText(.body)
                        }
                        .fixedSize(horizontal: !FeltAdaptiveLayout.stacksVertically(dynamicTypeSize), vertical: true)
                    }
                    SettingsRow(label: "Random checks",
                                footnote: "You're always asked at the end. Random checks come about once every 8 groups.") {
                        Toggle("Random checks", isOn: $setup.randomCheckpoints).labelsHidden()
                    }
                }
                PrimaryButton(title: "Start", action: onStart)
                    .accessibilityIdentifier("counting.start")
            }
            .padding(FeltSpacing.l)
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(title).feltText(.label).foregroundStyle(FeltColor.textTertiary)
            content()
        }
    }
}
