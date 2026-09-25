import SwiftUI

/// Segmented control on `surfaceInset`; the selected segment is cream.
struct ModePicker<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: FeltSpacing.xs) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(FeltMotion.ui) { selection = option }
                } label: {
                    Text(title(option))
                        .font(FeltType.body.font.weight(.semibold))
                        .foregroundStyle(isSelected ? FeltColor.onCream : FeltColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: FeltTapTarget.minimum)
                        .background(isSelected ? FeltColor.cream : .clear,
                                    in: RoundedRectangle(cornerRadius: FeltRadius.chip))
                        .contentShape(RoundedRectangle(cornerRadius: FeltRadius.chip))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(FeltSpacing.xs)
        .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip + FeltSpacing.xs))
    }
}
