import SwiftUI

/// Numeric keypad for running and true counts: 0–9, ±, .5, delete, enter.
struct CountKeypad: View {
    @Binding var entry: CountEntry
    var allowsHalf: Bool = true
    let onSubmit: (Double) -> Void

    private let digitRows: [[Int]] = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            Text(entry.display.isEmpty ? " " : entry.display)
                .feltText(.stat)
                .foregroundStyle(FeltColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip))
                .accessibilityLabel("Entered count")
                .accessibilityValue(entry.display.isEmpty ? "Empty" : entry.display)
            ForEach(digitRows, id: \.self) { row in
                HStack(spacing: FeltSpacing.s) {
                    ForEach(row, id: \.self) { key(.digit($0)) }
                }
            }
            HStack(spacing: FeltSpacing.s) {
                key(.sign)
                key(.digit(0))
                if allowsHalf {
                    key(.half)
                } else {
                    Color.clear.frame(maxWidth: .infinity, minHeight: 52)
                }
            }
            HStack(spacing: FeltSpacing.s) {
                key(.delete)
                key(.enter)
            }
        }
    }

    private func key(_ key: KeypadKey) -> some View {
        let isEnter = key == .enter
        let shape = RoundedRectangle(cornerRadius: FeltRadius.button)
        return Button {
            if let submitted = entry.apply(key) { onSubmit(submitted) }
        } label: {
            label(for: key)
                .font(FeltType.title.font)
                .foregroundStyle(isEnter ? FeltColor.onCream : FeltColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isEnter ? FeltColor.cream : FeltColor.surfaceInset, in: shape)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: key))
    }

    @ViewBuilder
    private func label(for key: KeypadKey) -> some View {
        switch key {
        case .digit(let d): Text(String(d))
        case .sign: Text("±")
        case .half: Text(".5")
        case .delete: Image(systemName: "delete.left")
        case .enter: Text("ENTER")
        }
    }

    private func accessibilityLabel(for key: KeypadKey) -> String {
        switch key {
        case .digit(let d): return String(d)
        case .sign: return "Toggle sign"
        case .half: return "Add one half"
        case .delete: return "Delete"
        case .enter: return "Enter"
        }
    }
}
