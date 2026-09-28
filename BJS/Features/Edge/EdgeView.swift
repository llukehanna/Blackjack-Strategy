import SwiftUI
import BJSCore

/// The Edge module: the house edge for any rules, live. It opens on the active rules; edits are
/// discarded on close unless applied. The result bar stays pinned above the scrolling content.
struct EdgeView: View {
    let onClose: () -> Void
    @Environment(ActiveRulesStore.self) private var rulesStore

    var body: some View {
        // The model is created once from the rules active at open (see EdgeScreen's @State).
        EdgeScreen(activeRules: rulesStore.rules, onClose: onClose)
    }
}

private struct EdgeScreen: View {
    let onClose: () -> Void
    @Environment(ActiveRulesStore.self) private var rulesStore
    @State private var model: EdgeViewModel
    @State private var confirmingApply = false
    @State private var showsToast = false

    init(activeRules: BlackjackRules, onClose: @escaping () -> Void) {
        self.onClose = onClose
        _model = State(initialValue: EdgeViewModel(activeRules: activeRules))
    }

    var body: some View {
        @Bindable var model = model
        let result = model.result
        ZStack {
            FeltBackground()
            VStack(spacing: 0) {
                resultBar(result)
                    .padding(.horizontal, FeltSpacing.l)
                    .padding(.bottom, FeltSpacing.m)
                Rectangle()
                    .fill(FeltColor.textTertiary.opacity(0.25))
                    .frame(height: 0.5)
                ScrollView {
                    VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                        breakdown(result)
                        RulesForm(rules: $model.rules)
                        applySection
                        Text(EdgeText.footnote)
                            .feltText(.body)
                            .foregroundStyle(FeltColor.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(FeltSpacing.l)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showsToast {
                FeltToast(text: EdgeText.toast)
                    .fixedSize()
                    .padding(.bottom, FeltSpacing.xl)
                    .transition(.opacity)
            }
        }
        .confirmationDialog(EdgeText.confirmTitle, isPresented: $confirmingApply, titleVisibility: .visible) {
            Button(EdgeText.confirmButton) {
                model.apply(to: rulesStore)
                flashToast()
            }
        } message: {
            Text(EdgeText.confirmMessage(summary: RulesSummary.text(for: model.rules)))
        }
    }

    private func resultBar(_ result: EdgeResult) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            HStack {
                CloseButton(identifier: "edge.close", action: onClose)
                Spacer()
                Text(EdgeText.headline(isPlayerEdge: model.isPlayerEdge))
                    .feltText(.label)
                    .foregroundStyle(FeltColor.textTertiary)
            }
            HStack(alignment: .firstTextBaseline, spacing: FeltSpacing.m) {
                Text(EdgeText.headlineNumber(result.houseEdge))
                    .feltText(.display)
                    .monospacedDigit()
                    .foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("edge.number")
                Text(model.rating.displayName)
                    .feltText(.body)
                    .foregroundStyle(ratingColor(model.rating))
                    .padding(.horizontal, FeltSpacing.m)
                    .padding(.vertical, FeltSpacing.xs)
                    .background(FeltColor.surfaceInset, in: Capsule())
                    .accessibilityIdentifier("edge.rating")
                Spacer(minLength: 0)
            }
            if let comparison = model.comparison {
                Text(EdgeText.comparison(comparison))
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                    .accessibilityIdentifier("edge.comparison")
            }
        }
    }

    private func breakdown(_ result: EdgeResult) -> some View {
        let scale = model.breakdownScale
        return SettingsSection(title: EdgeText.breakdownTitle) {
            SettingsRow(label: EdgeText.baselineLabel) {
                Text(EdgeText.edge(EdgeCalculator.baselineHouseEdge)).feltText(.body).monospacedDigit()
            }
            ForEach(result.contributions, id: \.factor) { contribution in
                EdgeContributionRow(
                    label: EdgeText.label(for: contribution.factor),
                    value: EdgeText.signedChange(contribution.edgeChange),
                    change: contribution.edgeChange,
                    scale: scale,
                    accessibilityText: EdgeText.accessibility(for: contribution.factor,
                                                              change: contribution.edgeChange))
            }
            SettingsRow(label: EdgeText.totalLabel) {
                Text(EdgeText.edge(result.houseEdge)).feltText(.body).monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var applySection: some View {
        if model.canApply {
            PrimaryButton(title: EdgeText.applyTitle) { confirmingApply = true }
                .accessibilityIdentifier("edge.apply")
        } else {
            Text(EdgeText.appliedCaption)
                .feltText(.body)
                .foregroundStyle(FeltColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .accessibilityIdentifier("edge.applied")
        }
    }

    private func ratingColor(_ rating: EdgeRating) -> Color {
        switch rating {
        case .good: return FeltColor.correct
        case .ok: return FeltColor.textSecondary
        case .poor: return FeltColor.incorrect
        }
    }

    /// Edge's toast follows a confirmation dialog's own dismissal animation, unlike the drills'
    /// (which show it mid-drill, with nothing else animating off). Starting immediately races
    /// that dismissal and the toast is gone before the sheet clears; `toastDelay` waits it out,
    /// and `toastVisibleDuration` (longer than `FeltToast.displayDuration`) keeps it up long
    /// enough to actually read once the dialog is out of the way.
    private static let toastDelay: Duration = .seconds(0.35)
    private static let toastVisibleDuration: Duration = .seconds(1.6)

    private func flashToast() {
        Task {
            try? await Task.sleep(for: Self.toastDelay)
            withAnimation(FeltMotion.ui) { showsToast = true }
            AccessibilityNotification.Announcement(EdgeText.toast).post()
            try? await Task.sleep(for: Self.toastVisibleDuration)
            withAnimation(FeltMotion.ui) { showsToast = false }
        }
    }
}
