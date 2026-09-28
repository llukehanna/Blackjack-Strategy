import SwiftUI
import BJSCore

struct StrategySummaryView: View {
    let summary: StrategySessionSummary
    let handsTarget: Int?
    let mode: StrategyMode
    let saveFailed: Bool
    let onWhy: (GradedDecision) -> Void
    let onAgain: () -> Void
    let onDone: () -> Void

    @State private var showsSaveAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                Text("Session summary").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("strategy.summary")
                LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                                    GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
                    StatChip(label: "Accuracy", value: PercentText.text(summary.accuracy))
                    StatChip(label: "Mistakes", value: "\(summary.mistakes.count)")
                    StatChip(label: "Best streak", value: "\(summary.bestStreak)")
                    StatChip(label: "Hands", value: "\(summary.handsPlayed)")
                    if let ms = summary.averageDecisionMs {
                        StatChip(label: "Avg decision", value: String(format: "%.1f s", ms / 1000))
                    }
                }
                if !summary.mistakes.isEmpty {
                    SettingsSection(title: "Mistakes") {
                        ForEach(summary.mistakes) { mistake in
                            Button { onWhy(mistake) } label: {
                                SettingsRow(label: TrainingText.handLabel(mistake.why)) {
                                    Text(mistakeValue(mistake))
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Explains the correct play")
                        }
                    }
                }
                PrimaryButton(title: "Again", action: onAgain)
                SecondaryButton(title: "Done", action: onDone)
            }
            .padding(FeltSpacing.l)
        }
        .onAppear { showsSaveAlert = saveFailed }
        .alert("Couldn't save this session", isPresented: $showsSaveAlert) {
            Button("OK") {}
        } message: {
            Text("Your results are shown here but won't appear in your progress.")
        }
    }

    private func mistakeValue(_ d: GradedDecision) -> String {
        let chosen: String
        switch d.chosen {
        case .timeout: chosen = "Time's up"
        case .action(let a): chosen = TrainingText.actionName(a)
        }
        return "\(chosen) → \(TrainingText.actionName(d.correctAction))"
    }
}
