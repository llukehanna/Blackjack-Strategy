/// What the user has typed on a `CountKeypad`: an optional minus sign, up to three
/// integer digits and, when the keypad allows it, a decimal point with up to two digits.
struct CountEntry: Equatable, Sendable {
    static let maxIntegerDigits = 3
    static let maxFractionDigits = 2

    private(set) var isNegative = false
    private(set) var integerDigits = ""
    /// nil until the decimal point is typed.
    private(set) var fractionDigits: String?

    init() {}

    var isEmpty: Bool { integerDigits.isEmpty && fractionDigits == nil }

    /// The typed number, or nil when nothing has been typed. "−0" is 0.
    var value: Double? {
        guard !isEmpty else { return nil }
        let whole = Double(integerDigits.isEmpty ? "0" : integerDigits) ?? 0
        var fraction = 0.0
        if let fractionDigits, !fractionDigits.isEmpty {
            fraction = Double("0." + fractionDigits) ?? 0
        }
        let magnitude = whole + fraction
        if magnitude == 0 { return 0 }
        return isNegative ? -magnitude : magnitude
    }

    /// What the display shows, using a true minus sign (U+2212): "0", "−12", "1.25", "0.".
    var display: String {
        let sign = isNegative ? "\u{2212}" : ""
        let whole = integerDigits.isEmpty ? "0" : integerDigits
        let fraction = fractionDigits.map { "." + $0 } ?? ""
        return sign + whole + fraction
    }

    mutating func appendDigit(_ digit: Int) {
        guard (0...9).contains(digit) else { return }
        if let fractionDigits {
            if fractionDigits.count < Self.maxFractionDigits {
                self.fractionDigits = fractionDigits + String(digit)
            }
        } else if integerDigits == "0" {
            integerDigits = String(digit)
        } else if integerDigits.count < Self.maxIntegerDigits {
            integerDigits += String(digit)
        }
    }

    mutating func appendDecimalPoint() {
        if fractionDigits == nil { fractionDigits = "" }
    }

    mutating func toggleSign() {
        isNegative.toggle()
    }

    /// Removes the last typed character: fraction digit, then the point, then integer digits, then the sign.
    mutating func deleteBackward() {
        if let fractionDigits {
            self.fractionDigits = fractionDigits.isEmpty ? nil : String(fractionDigits.dropLast())
        } else if !integerDigits.isEmpty {
            integerDigits.removeLast()
        } else {
            isNegative = false
        }
    }

    mutating func clear() {
        self = CountEntry()
    }
}
