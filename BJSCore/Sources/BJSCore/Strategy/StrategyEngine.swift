import Foundation

/// Produces and caches basic strategy tables for rule sets.
///
/// Charts come from Wizard of Odds' published basic strategy (see `WoOChartDecoder`).
/// Tables are built on first request and cached per rule set.
public final class StrategyEngine: @unchecked Sendable {

    private var cache: [BlackjackRules: StrategyTable] = [:]
    private let lock = NSLock()

    public init() {}

    /// Returns the strategy table for the given rules, building and caching it if needed.
    public func strategy(for rules: BlackjackRules) -> StrategyTable {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[rules] { return cached }
        let table = WoOChartDecoder.table(for: rules)
        cache[rules] = table
        return table
    }
}
