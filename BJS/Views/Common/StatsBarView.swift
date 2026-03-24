import SwiftUI

struct StatsBarView: View {
    let stats: SessionStats

    var body: some View {
        HStack(spacing: 0) {
            statChip(value: "\(Int(stats.accuracy))%", label: "Accuracy")
            thinDivider
            statChip(value: "\(stats.handCount)", label: "Hands")
            thinDivider
            statChip(value: "\(stats.errorCount)", label: "Errors")
        }
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
        }
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.body.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(width: 0.5, height: 24)
    }
}
