import SwiftUI

/// A label over a mono stat value, on `surfaceInset`.
struct StatChip: View {
    let label: String
    let value: String

    /// VoiceOver reads the em dash as "No data" rather than "em dash".
    static func accessibilityValue(for value: String) -> String {
        value == "—" ? "No data" : value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Text(label)
                .feltText(.label)
                .foregroundStyle(FeltColor.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .feltText(.stat)
                .foregroundStyle(FeltColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FeltSpacing.m)
        .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(Self.accessibilityValue(for: value))
    }
}
