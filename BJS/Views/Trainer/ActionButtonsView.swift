import SwiftUI
import BJSCore

struct ActionButtonsView: View {
    let availableActions: [Action]
    let isEnabled: Bool
    let onAction: (Action) -> Void

    private var primaryActions: [Action] {
        availableActions.filter { isPrimaryAction($0) }
    }

    private var secondaryActions: [Action] {
        availableActions.filter { !isPrimaryAction($0) }
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            if !primaryActions.isEmpty {
                actionRow(primaryActions)
            }
            if !secondaryActions.isEmpty {
                actionRow(secondaryActions)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    @ViewBuilder
    private func actionRow(_ actions: [Action]) -> some View {
        HStack(spacing: Spacing.smd) {
            ForEach(actions, id: \.self) { action in
                actionButton(action)
            }
        }
    }

    @ViewBuilder
    private func actionButton(_ action: Action) -> some View {
        Button {
            onAction(action)
        } label: {
            Text(action.rawValue.capitalized)
                .font(Typography.buttonLabel)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .fill(buttonFill(for: action))
                )
                .foregroundStyle(buttonLabelColor(for: action))
        }
        .disabled(!isEnabled)
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
            return .secondary
        }
        return isPrimaryAction(action) ? .white : .primary
    }
}
