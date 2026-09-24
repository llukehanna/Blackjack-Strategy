import BJSCore
import SwiftUI

/// Strategy setup (spec §5): mode, length and hand filter, then Start.
///
/// Pushed from the hub. `onStart` comes from the App layer, which records the launch for
/// Continue and presents the trainer full-screen, so this feature never names the hub.
struct StrategySetupView: View {
    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(Preferences.self) private var preferences
    @State private var mode: StrategyMode
    @State private var length: StrategySessionLength
    @State private var filter: HandFilter

    private let onStart: (StrategySessionConfig) -> Void

    /// `initial` prefills the pickers (the last setup used), or the defaults when nil.
    init(initial: StrategySessionConfig?, onStart: @escaping (StrategySessionConfig) -> Void) {
        let config = initial ?? StrategySessionConfig()
        self._mode = State(initialValue: config.mode)
        self._length = State(initialValue: config.length)
        self._filter = State(initialValue: config.filter)
        self.onStart = onStart
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                header
                SetupSection("Mode") {
                    ModePicker(StrategyMode.allCases, selection: $mode) { $0.displayName }
                    Text(modeDescription)
                        .feltType(.body)
                        .foregroundStyle(FeltColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("strategy.modeDescription")
                }
                SetupSection("Length") {
                    ModePicker(StrategySessionLength.allCases, selection: $length) { $0.displayName }
                }
                SetupSection("Hands") {
                    ModePicker(HandFilter.allCases, selection: $filter) { $0.displayName }
                }
                PrimaryButton("Start") {
                    onStart(StrategySessionConfig(mode: mode, length: length, filter: filter))
                }
                .accessibilityIdentifier("strategy.start")
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.xl)
        }
        .feltBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Text("Rules: \(RulesSummary.short(rulesStore.rules))")
                .feltType(.label)
                .foregroundStyle(FeltColor.textSecondary)
            Text("Strategy")
                .feltType(.display)
                .foregroundStyle(FeltColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("strategy.setup.title")
        }
    }

    private var modeDescription: String {
        guard mode == .speed else { return mode.setupDescription }
        let seconds = String(format: "%.1f", preferences.speedTimerSeconds)
        return "\(mode.setupDescription) \(seconds) s per decision (change it in Settings)."
    }
}

/// A labelled group on the setup screen: a `label`-style caption over its controls.
private struct SetupSection<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(title)
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}
