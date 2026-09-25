enum KeypadKey: Hashable {
    case digit(Int)
    case sign
    case half
    case delete
    case enter
}

/// The value being typed on `CountKeypad`. Pure state, so it is unit-tested without views.
struct CountEntry: Equatable {
    static let maxDigits = 3

    private(set) var digits = ""
    private(set) var isNegative = false
    private(set) var hasHalf = false

    var isEmpty: Bool { digits.isEmpty && !hasHalf }

    var value: Double? {
        guard !isEmpty else { return nil }
        let magnitude = Double(Int(digits) ?? 0) + (hasHalf ? 0.5 : 0)
        if magnitude == 0 { return 0 }
        return isNegative ? -magnitude : magnitude
    }

    var display: String {
        let sign = isNegative ? "\u{2212}" : ""
        guard !isEmpty else { return sign }
        return sign + (digits.isEmpty ? "0" : digits) + (hasHalf ? ".5" : "")
    }

    /// Applies one key press. Returns the submitted value on `.enter` (and clears), else nil.
    mutating func apply(_ key: KeypadKey) -> Double? {
        switch key {
        case .digit(let d):
            precondition((0...9).contains(d), "digit out of range")
            if digits == "0" {
                digits = String(d)
            } else if digits.count < Self.maxDigits {
                digits += String(d)
            }
        case .sign:
            isNegative.toggle()
        case .half:
            hasHalf.toggle()
        case .delete:
            if hasHalf {
                hasHalf = false
            } else if !digits.isEmpty {
                digits.removeLast()
            } else {
                isNegative = false
            }
        case .enter:
            guard let submitted = value else { return nil }
            self = CountEntry()
            return submitted
        }
        return nil
    }
}
