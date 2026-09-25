/// Builds a `StrategyTable` for a rule set from Wizard of Odds' published charts
/// (`WoOStrategyData`).
///
/// WoO's charts cover the deck group (1, 2, 4+), the soft-17 rule, DAS, surrender and
/// peek. 4, 6 and 8 decks share the "4 or more" chart. Rule options WoO does not model
/// leave the chart unchanged: resplit aces, hit split aces, max split hands and the
/// blackjack payout.
enum WoOChartDecoder {

    static let hardRows = 0..<17
    static let softRows = 17..<26
    static let pairRows = 26..<36

    static func table(for rules: BlackjackRules) -> StrategyTable {
        let source = sourceTable(for: rules)
        func grid(_ rows: Range<Int>) -> [[[Action]]] {
            rows.map { row in
                (0..<10).map { col in
                    let code = source[row][sourceColumn(col, peekRule: rules.peekRule)]
                    return preferences(code: code, row: row, col: col, rules: rules)
                }
            }
        }
        return StrategyTable(hardCells: grid(hardRows), softCells: grid(softRows),
                             pairCells: grid(pairRows))
    }

    static func sourceTable(for rules: BlackjackRules) -> [[String]] {
        let hits = rules.dealerSoft17 == .hits
        switch rules.deckCount {
        case .one: return hits ? WoOStrategyData.h17Deck1 : WoOStrategyData.s17Deck1
        case .two: return hits ? WoOStrategyData.h17Deck2 : WoOStrategyData.s17Deck2
        case .four, .six, .eight: return hits ? WoOStrategyData.h17Deck4Plus : WoOStrategyData.s17Deck4Plus
        }
    }

    /// Dealer 10 and A read WoO's European columns (10 and 11) under no hole card.
    static func sourceColumn(_ col: Int, peekRule: BlackjackRules.PeekRule) -> Int {
        peekRule == .europeanNoPeek && col >= 8 ? col + 2 : col
    }

    static func preferences(code: String, row: Int, col: Int, rules: BlackjackRules) -> [Action] {
        let das = rules.doubleAfterSplit
        var result: [Action]
        switch code {
        case "H": result = [.hit]
        case "S": result = [.stand]
        case "DH": result = [.double, .hit]
        case "DS": result = [.double, .stand]
        case "P": result = [.split]
        case "QH": result = das ? [.split] : [.hit]
        case "QD": result = das ? [.split] : [.double, .hit]
        case "QS": result = das ? [.split] : [.stand]
        case "RH": result = [.surrender, .hit]
        case "RS": result = [.surrender, .stand]
        case "RP": result = [.surrender, .split]
        default: fatalError("Unknown Wizard of Odds strategy code \(code)")
        }
        let chartSurrenders = result.first == .surrender
        result.removeAll { $0 == .surrender }
        if surrenders(chartSurrenders: chartSurrenders, row: row, col: col, rules: rules) {
            result.insert(.surrender, at: 0)
        }
        return result
    }

    /// Whether a cell surrenders under the rules' surrender option.
    static func surrenders(chartSurrenders: Bool, row: Int, col: Int, rules: BlackjackRules) -> Bool {
        rules.surrenderRule != .none && chartSurrenders
    }
}
