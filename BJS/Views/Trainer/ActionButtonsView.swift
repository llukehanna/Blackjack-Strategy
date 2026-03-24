import SwiftUI
import BJSCore

struct ActionButtonsView: View {
    let availableActions: [Action]
    let isEnabled: Bool
    let onAction: (Action) -> Void

    var body: some View {
        HStack(spacing: Spacing.smd) {
            ForEach(availableActions, id: \.self) { action in
                Button {
                    onAction(action)
                } label: {
                    Text(action.rawValue.capitalized)
                        .font(Typography.buttonLabel)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(buttonFill(for: action))
                        )
                        .foregroundStyle(buttonLabelColor(for: action))
                }
                .disabled(!isEnabled)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private func isPrimaryAction(_ action: Action) -> Bool {
        action == .hit || action == .stand
    }

    private func buttonFill(for action: Action) -> Color {
        if !isEnabled {
            return Color(.systemGray3)
        }
        return isPrimaryAction(action) ? BJSColors.accent : Color(.systemGray5)
    }

    private func buttonLabelColor(for action: Action) -> Color {
        if !isEnabled {
            return Color.secondary
        }
        return isPrimaryAction(action) ? .white : .primary
    }
}
