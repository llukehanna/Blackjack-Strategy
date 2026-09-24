import SwiftUI

/// Numeric keypad with ± for entering running and true counts (spec §4).
///
///     [ display ]
///     1  2  3
///     4  5  6
///     7  8  9
///     ±  0  .      ("." only when `allowsDecimal`)
///     ⌫  [ Enter ]
struct CountKeypad: View {
    @Binding private var entry: CountEntry
    private let allowsDecimal: Bool
    private let submitTitle: String
    private let onSubmit: (Double) -> Void

    private static let digitRows: [[Int]] = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    init(entry: Binding<CountEntry>, allowsDecimal: Bool = false, submitTitle: String = "Enter",
         onSubmit: @escaping (Double) -> Void) {
        self._entry = entry
        self.allowsDecimal = allowsDecimal
        self.submitTitle = submitTitle
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(spacing: FeltSpacing.s) {
            Text(entry.display)
                .feltType(.stat)
                .foregroundStyle(entry.isEmpty ? FeltColor.textTertiary : FeltColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget)
                .background(FeltColor.surfaceInset, in: RoundedRectangle(cornerRadius: FeltRadius.chip, style: .continuous))
                .accessibilityLabel("Entered count")
                .accessibilityValue(entry.isEmpty ? "Empty" : entry.display)
                .accessibilityIdentifier("keypad.display")

            Grid(horizontalSpacing: FeltSpacing.s, verticalSpacing: FeltSpacing.s) {
                ForEach(Self.digitRows, id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { digit in
                            digitKey(digit)
                        }
                    }
                }
                GridRow {
                    key("±", accessibilityLabel: "Change sign", identifier: "keypad.sign") {
                        entry.toggleSign()
                    }
                    digitKey(0)
                    if allowsDecimal {
                        key(".", accessibilityLabel: "Decimal point", identifier: "keypad.decimal") {
                            entry.appendDecimalPoint()
                        }
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: FeltMetrics.minTapTarget)
                            .accessibilityHidden(true)
                    }
                }
                GridRow {
                    Button {
                        entry.deleteBackward()
                    } label: {
                        Image(systemName: "delete.left")
                    }
                    .buttonStyle(.feltSecondary)
                    .accessibilityLabel("Delete")
                    .accessibilityIdentifier("keypad.delete")

                    Button(submitTitle) {
                        if let value = entry.value { onSubmit(value) }
                    }
                    .buttonStyle(.feltPrimary)
                    .disabled(entry.value == nil)
                    .gridCellColumns(2)
                    .accessibilityIdentifier("keypad.submit")
                }
            }
        }
    }

    private func digitKey(_ digit: Int) -> some View {
        key(String(digit), accessibilityLabel: String(digit), identifier: "keypad.digit.\(digit)") {
            entry.appendDigit(digit)
        }
    }

    private func key(_ text: String, accessibilityLabel: String, identifier: String,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).feltType(.stat)
        }
        .buttonStyle(.feltSecondary)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }
}
