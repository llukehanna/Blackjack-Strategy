import SwiftUI

struct SessionSummaryView: View {
    let stats: SessionStats
    let mistakes: [DecisionRecord]
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Heading
                Text("Session Complete")
                    .font(Typography.title)
                    .foregroundStyle(BJSColors.textPrimary)
                    .padding(.top, Spacing.lg)

                // Stats grid (2x2)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.md) {
                    statCard(label: "Hands Played", value: "\(stats.handCount)")
                    statCard(label: "Accuracy", value: "\(Int(stats.accuracy))%")
                    statCard(label: "Errors", value: "\(stats.errorCount)")
                    statCard(label: "Best Streak", value: "\(stats.bestStreak)")
                }
                .padding(.horizontal, Spacing.md)

                // Mistake Log
                if !mistakes.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Mistakes")
                            .font(Typography.caption)
                            .foregroundStyle(BJSColors.textSecondary)
                            .padding(.horizontal, Spacing.md)

                        ForEach(Array(mistakes.enumerated()), id: \.offset) { index, record in
                            VStack(spacing: 0) {
                                Text("\(record.handDescription) \u{2014} \(record.playerAction.rawValue.capitalized) \u{00B7} Correct: \(record.correctAction.rawValue.capitalized)")
                                    .font(Typography.body)
                                    .foregroundStyle(BJSColors.textPrimary)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if index < mistakes.count - 1 {
                                    Divider()
                                        .padding(.leading, Spacing.md)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Actions
                VStack(spacing: Spacing.sm) {
                    Button("Play Again") {
                        onPlayAgain()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    Button("Home") {
                        onHome()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
        }
        .background(BJSColors.surfaceBase)
    }

    @ViewBuilder
    private func statCard(label: String, value: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(BJSColors.textSecondary)
            Text(value)
                .font(Typography.body)
                .foregroundStyle(BJSColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(BJSColors.surfaceRaised)
        )
    }
}
