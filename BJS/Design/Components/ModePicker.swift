import SwiftUI

/// Segmented control on `surfaceInset`; the selected segment is cream (spec §4).
struct ModePicker<Option: Hashable>: View {
    private let options: [Option]
    @Binding private var selection: Option
    private let title: (Option) -> String

    init(_ options: [Option], selection: Binding<Option>, title: @escaping (Option) -> String) {
        self.options = options
        self._selection = selection
        self.title = title
    }

    var body: some View {
        HStack(spacing: FeltSpacing.xs) {
            ForEach(options, id: \.self) { option in
                segment(option)
            }
        }
        .padding(FeltSpacing.xs)
        .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous))
        .animation(FeltMotion.ui, value: selection)
    }

    private func segment(_ option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            selection = option
        } label: {
            Text(title(option))
                .feltType(.body)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? FeltColor.onCream : FeltColor.textSecondary)
                .padding(.horizontal, FeltSpacing.xs)
                .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget)
                .background {
                    if isSelected {
                        // Concentric with the track: track radius minus its padding.
                        RoundedRectangle(cornerRadius: FeltRadius.chip - FeltSpacing.xs, style: .continuous)
                            .fill(FeltColor.cream)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
