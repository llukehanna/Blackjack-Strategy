import SwiftUI

/// A tappable module entry: title and subtitle on `surfaceInset`.
struct ModuleTile: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FeltSpacing.m) {
                VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                    Text(title)
                        .feltText(.title)
                        .foregroundStyle(FeltColor.textPrimary)
                    Text(subtitle)
                        .feltText(.body)
                        .foregroundStyle(FeltColor.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(FeltColor.textTertiary)
            }
            .padding(FeltSpacing.l)
            .frame(maxWidth: .infinity, minHeight: FeltTapTarget.minimum, alignment: .leading)
            .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.tile))
            .contentShape(RoundedRectangle(cornerRadius: FeltRadius.tile))
        }
        .buttonStyle(.plain)
    }
}
