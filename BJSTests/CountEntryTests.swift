import Testing
@testable import BJS

@Suite("CountEntry")
struct CountEntryTests {

    private func typed(_ keys: String) -> CountEntry {
        var entry = CountEntry()
        for key in keys {
            switch key {
            case "-": entry.toggleSign()
            case ".": entry.appendDecimalPoint()
            case "<": entry.deleteBackward()
            default: entry.appendDigit(Int(String(key))!)
            }
        }
        return entry
    }

    @Test("Empty entry shows 0 and has no value")
    func empty() {
        let entry = CountEntry()
        #expect(entry.isEmpty)
        #expect(entry.value == nil)
        #expect(entry.display == "0")
    }

    @Test("Digits build an integer", arguments: [
        ("12", 12.0, "12"),
        ("-12", -12.0, "\u{2212}12"),
        ("12-", -12.0, "\u{2212}12"),
        ("--7", 7.0, "7"),
        ("0", 0.0, "0"),
        ("-0", 0.0, "\u{2212}0"),
    ])
    func integers(_ keys: String, _ value: Double, _ display: String) {
        let entry = typed(keys)
        #expect(entry.value == value)
        #expect(entry.display == display)
    }

    @Test("No leading zeros")
    func leadingZero() {
        #expect(typed("05").display == "5")
        #expect(typed("00").display == "0")
    }

    @Test("At most three integer digits")
    func integerLimit() {
        #expect(typed("1234").value == 123)
    }

    @Test("Decimals: one point, at most two fraction digits")
    func decimals() {
        #expect(typed("1.25").value == 1.25)
        #expect(typed("1.259").value == 1.25)
        #expect(typed("1..5").value == 1.5)
        #expect(typed(".5").display == "0.5")
        #expect(typed(".5").value == 0.5)
        #expect(typed("-1.5").value == -1.5)
        #expect(typed("2.").display == "2.")
        #expect(typed("2.").value == 2)
    }

    @Test("Delete removes fraction digits, then the point, then digits, then the sign")
    func delete() {
        #expect(typed("1.25<").display == "1.2")
        #expect(typed("1.2<<").display == "1")
        #expect(typed("-12<").display == "\u{2212}1")
        #expect(typed("-1<<").display == "0")
        #expect(typed("-1<<").isEmpty)
        #expect(typed("<").isEmpty)
    }

    @Test("Clear resets everything")
    func clear() {
        var entry = typed("-1.5")
        entry.clear()
        #expect(entry == CountEntry())
    }

    @Test("Out-of-range digits are ignored")
    func badDigit() {
        var entry = CountEntry()
        entry.appendDigit(10)
        entry.appendDigit(-1)
        #expect(entry.isEmpty)
    }
}
