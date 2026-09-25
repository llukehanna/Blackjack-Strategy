import SwiftUI

/// A titled group of `SettingsRow`s on `surfaceInset`, with hairline separators between rows.
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(title)
                .feltText(.label)
                .foregroundStyle(FeltColor.textTertiary)
                .padding(.leading, FeltSpacing.l)
            VStack(spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        if index > 0 {
                            Rectangle()
                                .fill(FeltColor.textTertiary.opacity(0.25))
                                .frame(height: 0.5)
                                .padding(.leading, FeltSpacing.l)
                        }
                        row
                    }
                }
            }
            .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.tile))
        }
    }
}

/// Label on the left, a value/toggle/picker accessory on the right, optional footnote below.
struct SettingsRow<Accessory: View>: View {
    let label: String
    var footnote: String? = nil
    @ViewBuilder let accessory: Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            HStack(spacing: FeltSpacing.m) {
                Text(label)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textPrimary)
                Spacer(minLength: FeltSpacing.s)
                accessory
                    .foregroundStyle(FeltColor.textSecondary)
                    .tint(FeltColor.textSecondary)
            }
            .frame(minHeight: FeltTapTarget.minimum)
            if let footnote {
                Text(footnote)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.vertical, FeltSpacing.xs)
    }
}
