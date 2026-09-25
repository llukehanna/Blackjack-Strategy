import Testing
@testable import BJSCore

@Suite("Wizard of Odds raw strategy data")
struct WoOStrategyDataTests {

    static let tables: [(String, [[String]])] = [
        ("s17Deck1", WoOStrategyData.s17Deck1), ("h17Deck1", WoOStrategyData.h17Deck1),
        ("s17Deck2", WoOStrategyData.s17Deck2), ("h17Deck2", WoOStrategyData.h17Deck2),
        ("s17Deck4Plus", WoOStrategyData.s17Deck4Plus), ("h17Deck4Plus", WoOStrategyData.h17Deck4Plus),
    ]

    static let knownCodes: Set<String> = ["H", "S", "DH", "DS", "P", "QH", "QD", "QS", "RH", "RS", "RP"]

    @Test("Six tables of 36 rows x 12 columns")
    func shape() {
        for (name, table) in Self.tables {
            #expect(table.count == 36, "\(name)")
            #expect(table.allSatisfy { $0.count == 12 }, "\(name)")
        }
    }

    @Test("Every cell is a known WoO code")
    func knownCodesOnly() {
        for (name, table) in Self.tables {
            let unknown = Set(table.flatMap { $0 }).subtracting(Self.knownCodes)
            #expect(unknown.isEmpty, "\(name): \(unknown)")
        }
    }

    @Test("Hard 17+ never hits; pairs of aces always split under peek")
    func sanity() {
        for (name, table) in Self.tables {
            for row in 12...16 {  // hard 17-21
                #expect(!table[row].contains("H"), "\(name) row \(row)")
            }
            #expect(Array(table[35][0..<10]) == Array(repeating: "P", count: 10), "\(name) A,A")
        }
    }
}
