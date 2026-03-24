import SwiftUI
import BJSCore

struct ActionButtonsView: View {
    let availableActions: [Action]
    let isEnabled: Bool
    let onAction: (Action) -> Void

    var body: some View {
        HStack(spacing: 16) {
            ForEach(availableActions, id: \.self) { action in
                Button {
                    onAction(action)
                } label: {
                    Text(action.rawValue.capitalized)
                        .font(.body.bold())
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isEnabled ? Color(.systemGray5) : Color(.systemGray3))
                        )
                        .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
                }
                .disabled(!isEnabled)
            }
        }
        .padding(.horizontal, 16)
    }
}
