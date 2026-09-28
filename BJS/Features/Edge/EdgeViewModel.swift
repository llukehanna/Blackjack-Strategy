import Foundation
import Observation
import BJSCore

/// The Edge screen's state: the rules being evaluated (a copy of the active rules at open) and
/// everything derived from them. Nothing is persisted; the maths is `EdgeCalculator`'s.
///
/// `result` is computed once per `rules` change (on `init` and on `didSet`) rather than on every
/// access, since a single `body` evaluation reads several derived properties.
@MainActor
@Observable
final class EdgeViewModel {
    var rules: BlackjackRules {
        didSet { result = calculator.analyze(rules: rules) }
    }
    private(set) var activeRules: BlackjackRules

    private(set) var result: EdgeResult

    @ObservationIgnored private let calculator = EdgeCalculator()

    init(activeRules: BlackjackRules) {
        self.rules = activeRules
        self.activeRules = activeRules
        self.result = calculator.analyze(rules: activeRules)
    }

    var rating: EdgeRating { EdgeRating(houseEdge: result.houseEdge) }

    var isPlayerEdge: Bool { result.houseEdge < 0 }

    /// The form's edge less the active rules' edge; nil when they are the same rules.
    var comparison: Double? {
        rules == activeRules ? nil : result.houseEdge - calculator.houseEdge(for: activeRules)
    }

    var canApply: Bool { rules != activeRules }

    /// Breakdown bars are drawn relative to the largest change on screen. The floor keeps a
    /// lone tiny change from filling the bar.
    var breakdownScale: Double {
        max(result.contributions.map { abs($0.edgeChange) }.max() ?? 0, 0.01)
    }

    func apply(to store: ActiveRulesStore) {
        store.rules = rules
        activeRules = store.rules
    }
}
