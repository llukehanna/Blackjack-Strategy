import Testing
@testable import BJSCore

@Suite("BlackjackRules")
struct RulesTests {

    // MARK: - Default values

    @Test("Default BlackjackRules produces standard 6-deck S17 DAS game")
    func defaultRules() {
        let rules = BlackjackRules()
        #expect(rules.deckCount == .six)
        #expect(rules.dealerSoft17 == .stands)
        #expect(rules.blackjackPayout == .threeToTwo)
        #expect(rules.doubleAfterSplit == true)
        #expect(rules.resplitAces == false)
        #expect(rules.hitSplitAces == false)
        #expect(rules.maxSplitHands == 4)
        #expect(rules.surrenderRule == .none)
        #expect(rules.doubleRestriction == .anyTwo)
        #expect(rules.peekRule == .americanPeek)
    }

    // MARK: - Hashable

    @Test("Two default rules instances are equal")
    func hashableEqual() {
        let a = BlackjackRules()
        let b = BlackjackRules()
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Changing dealerSoft17 produces different hash")
    func hashableNotEqual() {
        let a = BlackjackRules()
        var b = BlackjackRules()
        b.dealerSoft17 = .hits
        #expect(a != b)
    }

    @Test("Changing any single property produces inequality")
    func hashableEachPropertyMatters() {
        let baseline = BlackjackRules()

        var r1 = baseline; r1.deckCount = .one
        #expect(r1 != baseline)

        var r2 = baseline; r2.blackjackPayout = .sixToFive
        #expect(r2 != baseline)

        var r3 = baseline; r3.doubleAfterSplit = false
        #expect(r3 != baseline)

        var r4 = baseline; r4.resplitAces = true
        #expect(r4 != baseline)

        var r5 = baseline; r5.hitSplitAces = true
        #expect(r5 != baseline)

        var r6 = baseline; r6.maxSplitHands = 2
        #expect(r6 != baseline)

        var r7 = baseline; r7.surrenderRule = .late
        #expect(r7 != baseline)

        var r8 = baseline; r8.doubleRestriction = .tenToEleven
        #expect(r8 != baseline)

        var r9 = baseline; r9.peekRule = .europeanNoPeek
        #expect(r9 != baseline)
    }

    // MARK: - Codable

    @Test("BlackjackRules round-trips through JSON encoding/decoding")
    func codableRoundTrip() throws {
        let original = BlackjackRules()
        let decoded = try CodableTestHelper.jsonRoundTrip(original)
        #expect(decoded == original)
    }

    @Test("Custom-configured rules round-trip correctly")
    func codableCustomRoundTrip() throws {
        var rules = BlackjackRules()
        rules.deckCount = .two
        rules.dealerSoft17 = .hits
        rules.blackjackPayout = .sixToFive
        rules.doubleAfterSplit = false
        rules.resplitAces = true
        rules.hitSplitAces = true
        rules.maxSplitHands = 2
        rules.surrenderRule = .early
        rules.doubleRestriction = .nineToEleven
        rules.peekRule = .europeanNoPeek

        let decoded = try CodableTestHelper.jsonRoundTrip(rules)
        #expect(decoded == rules)
    }

    // MARK: - DeckCount enum

    @Test("All DeckCount cases exist with correct raw values")
    func deckCountCases() {
        #expect(BlackjackRules.DeckCount.allCases.count == 5)
        #expect(BlackjackRules.DeckCount.one.rawValue == 1)
        #expect(BlackjackRules.DeckCount.two.rawValue == 2)
        #expect(BlackjackRules.DeckCount.four.rawValue == 4)
        #expect(BlackjackRules.DeckCount.six.rawValue == 6)
        #expect(BlackjackRules.DeckCount.eight.rawValue == 8)
    }

    // MARK: - RULE-01 coverage

    @Test("All 11 RULE-01 properties are accessible on a custom-configured instance")
    func rule01Coverage() {
        var rules = BlackjackRules()
        rules.deckCount = .eight
        rules.dealerSoft17 = .hits
        rules.blackjackPayout = .twoToOne
        rules.doubleAfterSplit = false
        rules.resplitAces = true
        rules.hitSplitAces = true
        rules.maxSplitHands = 3
        rules.surrenderRule = .late
        rules.doubleRestriction = .tenToEleven
        rules.peekRule = .europeanNoPeek

        #expect(rules.deckCount == .eight)
        #expect(rules.dealerSoft17 == .hits)
        #expect(rules.blackjackPayout == .twoToOne)
        #expect(rules.doubleAfterSplit == false)
        #expect(rules.resplitAces == true)
        #expect(rules.hitSplitAces == true)
        #expect(rules.maxSplitHands == 3)
        #expect(rules.surrenderRule == .late)
        #expect(rules.doubleRestriction == .tenToEleven)
        #expect(rules.peekRule == .europeanNoPeek)
    }

    // MARK: - Nested enum completeness

    @Test("DealerSoft17 has both cases")
    func dealerSoft17Cases() {
        let cases = BlackjackRules.DealerSoft17.allCases
        #expect(cases.contains(.stands))
        #expect(cases.contains(.hits))
    }

    @Test("BlackjackPayout has all three cases")
    func blackjackPayoutCases() {
        let cases = BlackjackRules.BlackjackPayout.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.threeToTwo))
        #expect(cases.contains(.sixToFive))
        #expect(cases.contains(.twoToOne))
    }

    @Test("SurrenderRule has all three cases")
    func surrenderRuleCases() {
        let cases = BlackjackRules.SurrenderRule.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.none))
        #expect(cases.contains(.late))
        #expect(cases.contains(.early))
    }

    @Test("DoubleRestriction has all three cases")
    func doubleRestrictionCases() {
        let cases = BlackjackRules.DoubleRestriction.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.anyTwo))
        #expect(cases.contains(.nineToEleven))
        #expect(cases.contains(.tenToEleven))
    }

    @Test("PeekRule has both cases")
    func peekRuleCases() {
        let cases = BlackjackRules.PeekRule.allCases
        #expect(cases.count == 2)
        #expect(cases.contains(.americanPeek))
        #expect(cases.contains(.europeanNoPeek))
    }
}
