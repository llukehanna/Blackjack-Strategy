import SwiftUI

/// The × that closes a module screen or sheet (not a Felt component; built from tokens).
struct CloseButton: View {
    var identifier = "close"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(FeltColor.textSecondary)
                .frame(width: FeltTapTarget.minimum, height: FeltTapTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
        .accessibilityIdentifier(identifier)
    }
}
