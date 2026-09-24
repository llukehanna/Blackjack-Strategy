import BJSCore
import SwiftUI

/// Session summary (spec §5): accuracy, mistakes, best streak, hands played, and the mean
/// decision time in Speed mode; each mistake opens its WHY sheet.
struct StrategySummaryView: View {
    private let viewModel: StrategyTrainerViewModel
    private let onDone: () -> Void

    @Environment(\.displayScale) private var displayScale

    init(viewModel: StrategyTrainerViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
    }

    var body: some View {
        let summary = viewModel.summary
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    Text("\(viewModel.config.mode.displayName) · \(viewModel.config.filter.longName)")
                        .feltType(.label)
                        .foregroundStyle(FeltColor.textSecondary)
                    Text("Summary")
                        .feltType(.display)
                        .foregroundStyle(FeltColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("summary.title")
                }
                stats(summary)
                mistakes(summary)
                PrimaryButton("Done", action: onDone)
                    .accessibilityIdentifier("summary.done")
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.xl)
        }
    }

    private func stats(_ summary: StrategySessionSummary) -> some View {
        Grid(horizontalSpacing: FeltSpacing.s, verticalSpacing: FeltSpacing.s) {
            GridRow {
                StatChip(label: "Accuracy", value: StrategyText.percent(summary.accuracy))
                    .accessibilityIdentifier("summary.accuracy")
                StatChip(label: "Mistakes", value: "\(summary.mistakeCount)")
                    .accessibilityIdentifier("summary.mistakes")
            }
            GridRow {
                StatChip(label: "Best streak", value: "\(summary.bestStreak)")
                    .accessibilityIdentifier("summary.bestStreak")
                StatChip(label: "Hands", value: "\(summary.handsPlayed)")
                    .accessibilityIdentifier("summary.hands")
            }
            if viewModel.config.mode.isTimed {
                GridRow {
                    StatChip(label: "Avg decision", value: StrategyText.seconds(fromMs: summary.meanResponseMs))
                        .accessibilityIdentifier("summary.meanTime")
                        .gridCellColumns(2)
                }
            }
        }
    }

    private func mistakes(_ summary: StrategySessionSummary) -> some View {
        SettingsSection("Mistakes") {
            if summary.mistakes.isEmpty {
                Text("No mistakes this session.")
                    .feltType(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget, alignment: .leading)
                    .padding(.horizontal, FeltSpacing.l)
            } else {
                ForEach(summary.mistakes) { mistake in
                    mistakeRow(mistake, showsSeparator: mistake.sequence != summary.mistakes.last?.sequence)
                }
            }
        }
    }

    private func mistakeRow(_ mistake: GradedDecision, showsSeparator: Bool) -> some View {
        Button {
            viewModel.showWhy(for: mistake)
        } label: {
            HStack(spacing: FeltSpacing.m) {
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    Text("Hand \(mistake.handNumber) · \(DecisionFeedback.spotTitle(mistake.cell))")
                        .feltType(.body)
                        .foregroundStyle(FeltColor.textPrimary)
                    Text(StrategyText.mistakeDetail(mistake))
                        .feltType(.body)
                        .foregroundStyle(FeltColor.textSecondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: FeltSpacing.s)
                Text("Why")
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textSecondary)
                Image(systemName: "chevron.right")
                    .feltType(.label)
                    .foregroundStyle(FeltColor.textTertiary)
            }
            .padding(.horizontal, FeltSpacing.l)
            .padding(.vertical, FeltSpacing.s)
            .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget, alignment: .leading)
            .overlay(alignment: .bottom) {
                if showsSeparator {
                    // Same hairline as SettingsRow: textTertiary at 30%, one pixel.
                    Rectangle()
                        .fill(FeltColor.textTertiary.opacity(0.3))
                        .frame(height: 1 / displayScale)
                        .padding(.leading, FeltSpacing.l)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(FeltPressableStyle())
        .accessibilityHint("Shows why")
        .accessibilityIdentifier("summary.mistake.\(mistake.sequence)")
    }
}
