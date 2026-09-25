import Testing
@testable import BJSCore

/// One of WoO's rendered charts, with the `BlackjackRules` it corresponds to.
struct WoOChart: Sendable, CustomTestStringConvertible {
    let key: String
    let rows: [(name: String, codes: [String])]

    var testDescription: String { key }

    var rules: BlackjackRules {
        var fields: [String: String] = [:]
        for pair in key.split(separator: " ") {
            let parts = pair.split(separator: "=")
            fields[String(parts[0])] = String(parts[1])
        }
        var r = BlackjackRules()
        r.deckCount = ["1": .one, "2": .two, "4+": .six][fields["decks"]!]!
        r.dealerSoft17 = fields["soft17"] == "H17" ? .hits : .stands
        r.doubleAfterSplit = fields["das"] == "yes"
        r.surrenderRule = fields["surrender"] == "any" ? .late : .none
        r.peekRule = fields["peek"] == "enhc" ? .europeanNoPeek : .americanPeek
        return r
    }

    static let all: [WoOChart] = {
        var charts: [WoOChart] = []
        var key = ""
        var rows: [(name: String, codes: [String])] = []
        for line in wooRenderedCharts.split(separator: "\n") {
            if line.hasPrefix("# ") {
                if !key.isEmpty { charts.append(WoOChart(key: key, rows: rows)) }
                key = String(line.dropFirst(2))
                rows = []
            } else {
                let parts = line.split(separator: " ").map(String.init)
                rows.append((name: parts[0], codes: Array(parts.dropFirst())))
            }
        }
        charts.append(WoOChart(key: key, rows: rows))
        return charts
    }()
}

/// WoO's display code for a preference list.
func wooDisplayCode(_ preferences: [Action]) -> String {
    switch preferences {
    case [.hit]: return "H"
    case [.stand]: return "S"
    case [.double, .hit]: return "Dh"
    case [.double, .stand]: return "Ds"
    case [.split]: return "P"
    case [.surrender, .hit]: return "Rh"
    case [.surrender, .stand]: return "Rs"
    case [.surrender, .split]: return "Rp"
    default: return "?\(preferences)"
    }
}

@Suite("Strategy matches Wizard of Odds charts")
struct WoOChartTests {

    @Test("Fixture holds 48 charts of 36 rows x 10 columns")
    func fixtureShape() {
        #expect(WoOChart.all.count == 48)
        #expect(WoOChart.all.allSatisfy { $0.rows.count == 36 && $0.rows.allSatisfy { $0.codes.count == 10 } })
    }

    @Test("Every cell matches WoO", arguments: WoOChart.all)
    func everyCellMatches(chart: WoOChart) {
        let table = StrategyEngine().strategy(for: chart.rules)
        let ours = table.hardCells + table.softCells + table.pairCells
        for (r, row) in chart.rows.enumerated() {
            for c in 0..<10 {
                #expect(wooDisplayCode(ours[r][c]) == row.codes[c], "\(row.name) vs column \(c)")
            }
        }
    }
}
