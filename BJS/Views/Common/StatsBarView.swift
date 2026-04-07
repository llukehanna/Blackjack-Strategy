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
        .background(BJSColors.surfaceRaised)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BJSColors.borderSubtle)
                .frame(height: 0.5)
        }
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(Typography.body)
                .foregroundStyle(BJSColors.textPrimary)
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(BJSColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(BJSColors.borderSubtle)
            .frame(width: 0.5, height: 24)
    }
}
