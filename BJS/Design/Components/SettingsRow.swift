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
///
/// At accessibility Dynamic Type sizes the label and accessory no longer fit side by side, so the
/// row switches to a vertical layout: the label on its own line, the accessory below it, both
/// leading-aligned. `AnyLayout` keeps the label's and accessory's view identity stable across that
/// switch.
struct SettingsRow<Accessory: View>: View {
    let label: String
    var footnote: String? = nil
    @ViewBuilder let accessory: Accessory

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let stacksVertically = FeltAdaptiveLayout.stacksVertically(dynamicTypeSize)
        let rowLayout: AnyLayout = stacksVertically
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: FeltSpacing.xs))
            : AnyLayout(HStackLayout(spacing: FeltSpacing.m))
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            rowLayout {
                Text(label)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textPrimary)
                    .frame(maxWidth: stacksVertically ? .infinity : nil, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if !stacksVertically {
                    Spacer(minLength: FeltSpacing.s)
                }
                // At accessibility sizes a system control (Picker(.menu), Link, Menu) can report
                // an intrinsic width wider than the screen and refuse to shrink on its own, which
                // would blow up this row — and every sibling row sharing its section's background —
                // past the screen edges. Cap it: propose the full leading-aligned row width, and let
                // it wrap up to 2 lines or scale down rather than impose its own width.
                accessory
                    .foregroundStyle(FeltColor.textSecondary)
                    .tint(FeltColor.textSecondary)
                    .frame(maxWidth: stacksVertically ? .infinity : nil, alignment: .leading)
                    .lineLimit(stacksVertically ? 2 : nil)
                    .minimumScaleFactor(stacksVertically ? 0.5 : 1)
            }
            .frame(minHeight: FeltTapTarget.minimum)
            if let footnote {
                Text(footnote)
                    .feltText(.body)
                    .foregroundStyle(FeltColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: stacksVertically ? .infinity : nil, alignment: .leading)
        .padding(.horizontal, FeltSpacing.l)
        .padding(.vertical, FeltSpacing.xs)
    }
}
