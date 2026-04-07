import SwiftUI

struct TrainingModeToggle: View {
    @Binding var selection: TrainingMode

    var body: some View {
        HStack(spacing: 0) {
            cell(.learn, label: "Learn")
            cell(.test, label: "Test")
        }
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .stroke(BJSColors.borderSubtle, lineWidth: 0.5)
        )
        .padding(.horizontal, Spacing.md)
    }

    @ViewBuilder
    private func cell(_ mode: TrainingMode, label: String) -> some View {
        Button {
            selection = mode
        } label: {
            Text(label)
                .font(Typography.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(selection == mode ? BJSColors.accentGold : BJSColors.surfaceRaised)
                .foregroundStyle(selection == mode ? BJSColors.textOnOverlay : BJSColors.textSecondary)
        }
        .buttonStyle(.plain)
    }
}
