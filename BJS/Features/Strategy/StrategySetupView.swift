import SwiftUI
import BJSCore

struct StrategySetupView: View {
    @Binding var setup: StrategySetup
    let weakSpotsReady: Bool
    let onStart: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                HStack {
                    Text("Strategy").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                    Spacer()
                    CloseButton(action: onClose)
                }
                group("Mode") {
                    ModePicker(options: StrategyMode.allCases, selection: $setup.mode) { $0.title }
                    Text(setup.mode.blurb).feltText(.body).foregroundStyle(FeltColor.textSecondary)
                    if setup.mode == .weakSpots && !weakSpotsReady {
                        Text("Not enough history yet: hands are dealt evenly.")
                            .feltText(.body).foregroundStyle(FeltColor.brass)
                    }
                }
                group("Length") {
                    ModePicker(options: StrategyLength.options, selection: $setup.length) { $0.title }
                }
                group("Hands") {
                    ModePicker(options: HandFilter.allCases, selection: $setup.filter) { $0.title }
                }
                PrimaryButton(title: "Start", action: onStart)
                    .accessibilityIdentifier("strategy.start")
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

/// The × used on Strategy screens (not a Felt component; built from tokens).
struct CloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(FeltColor.textSecondary)
                .frame(width: FeltTapTarget.minimum, height: FeltTapTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
        .accessibilityIdentifier("strategy.close")
    }
}
