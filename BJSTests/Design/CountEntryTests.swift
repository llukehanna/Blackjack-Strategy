import Testing
@testable import BJS

@MainActor
struct CountEntryTests {

    func entry(_ keys: [KeypadKey]) -> CountEntry {
        var e = CountEntry()
        for key in keys { _ = e.apply(key) }
        return e
    }

    @Test("Empty entry has no value and an empty display")
    func empty() {
        let e = CountEntry()
        #expect(e.isEmpty)
        #expect(e.value == nil)
        #expect(e.display == "")
    }

    @Test("Digits build a whole number")
    func digits() {
        let e = entry([.digit(1), .digit(2)])
        #expect(e.value == 12)
        #expect(e.display == "12")
    }

    @Test("A leading zero is replaced")
    func leadingZero() {
        #expect(entry([.digit(0), .digit(7)]).display == "7")
        #expect(entry([.digit(0), .digit(0)]).display == "0")
    }

    @Test("At most three digits")
    func maxDigits() {
        #expect(entry([.digit(1), .digit(2), .digit(3), .digit(4)]).value == 123)
    }

    @Test("Sign toggles negative and displays a real minus sign")
    func sign() {
        let e = entry([.digit(4), .sign])
        #expect(e.value == -4)
        #expect(e.display == "\u{2212}4")
        #expect(entry([.digit(4), .sign, .sign]).value == 4)
        #expect(entry([.sign]).display == "\u{2212}")
        #expect(entry([.sign]).value == nil)
    }

    @Test("Half adds .5, including on its own and with a sign")
    func half() {
        #expect(entry([.digit(2), .half]).value == 2.5)
        #expect(entry([.digit(2), .half]).display == "2.5")
        #expect(entry([.half]).value == 0.5)
        #expect(entry([.half]).display == "0.5")
        #expect(entry([.digit(1), .half, .sign]).value == -1.5)
        #expect(entry([.digit(2), .half, .half]).value == 2)
    }

    @Test("Negative zero is zero")
    func negativeZero() {
        let e = entry([.digit(0), .sign])
        #expect(e.value == 0)
        #expect(e.value?.sign == .plus)
    }

    @Test("Delete removes the half, then digits, then the sign")
    func delete() {
        var e = entry([.digit(1), .digit(2), .half, .sign])
        _ = e.apply(.delete)
        #expect(e.value == -12)
        _ = e.apply(.delete)
        #expect(e.value == -1)
        _ = e.apply(.delete)
        #expect(e.display == "\u{2212}")
        _ = e.apply(.delete)
        #expect(e == CountEntry())
    }

    @Test("Enter submits the value and clears; enter on empty does nothing")
    func enter() {
        var e = entry([.digit(3), .sign])
        #expect(e.apply(.enter) == -3)
        #expect(e == CountEntry())
        #expect(e.apply(.enter) == nil)
    }
}
