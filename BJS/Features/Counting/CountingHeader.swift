import SwiftUI

/// Title row for Counting's setup and reference screens, with a back chevron to the Counting menu.
struct CountingHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: FeltSpacing.xs) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FeltColor.textSecondary)
                    .frame(width: FeltTapTarget.minimum, height: FeltTapTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("counting.back")
            Text(title).feltText(.display).foregroundStyle(FeltColor.textPrimary)
            Spacer()
        }
    }
}
