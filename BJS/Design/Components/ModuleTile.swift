import SwiftUI

/// A tappable title + subtitle tile on `surfaceInset` (spec §4). Used for the hub's modules.
struct ModuleTile: View {
    private let title: String
    private let subtitle: String
    private let action: () -> Void

    init(title: String, subtitle: String, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: FeltSpacing.xs) {
                Text(title)
                    .feltType(.title)
                    .foregroundStyle(FeltColor.textPrimary)
                Text(subtitle)
                    .feltType(.body)
                    .foregroundStyle(FeltColor.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(FeltSpacing.l)
            .frame(minHeight: FeltMetrics.minTapTarget * 2)
            .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.tile, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: FeltRadius.tile, style: .continuous))
        }
        .buttonStyle(FeltPressableStyle())
    }
}
