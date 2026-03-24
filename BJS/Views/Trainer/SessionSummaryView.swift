import SwiftUI

struct SessionSummaryView: View {
    let stats: SessionStats
    let mistakes: [DecisionRecord]
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Heading
                Text("Session Complete")
                    .font(.title2.bold())
                    .padding(.top, 24)

                // Stats grid (2x2)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    statCard(label: "Hands Played", value: "\(stats.handCount)")
                    statCard(label: "Accuracy", value: "\(Int(stats.accuracy))%")
                    statCard(label: "Errors", value: "\(stats.errorCount)")
                    statCard(label: "Best Streak", value: "\(stats.bestStreak)")
                }
                .padding(.horizontal, 16)

                // Mistake Log
                if !mistakes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mistakes")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)

                        ForEach(Array(mistakes.enumerated()), id: \.offset) { _, record in
                            Text("\(record.handDescription) \u{2014} \(record.playerAction.rawValue.capitalized) \u{00B7} Correct: \(record.correctAction.rawValue.capitalized)")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Actions
                VStack(spacing: 12) {
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
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private func statCard(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
