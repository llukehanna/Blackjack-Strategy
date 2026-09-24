import SwiftUI

/// A label over a monospaced stat value, on `surfaceInset` (spec §4).
struct StatChip: View {
    private let label: String
    private let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FeltSpacing.xs) {
            Text(label)
                .feltType(.label)
                .foregroundStyle(FeltColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .feltType(.stat)
                .foregroundStyle(FeltColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FeltSpacing.m)
        .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
