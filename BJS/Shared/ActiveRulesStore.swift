import Foundation
import Observation
import os
import BJSCore

/// The one app-wide active rule set (parent spec §3 rule 4), persisted as JSON in UserDefaults.
@Observable
final class ActiveRulesStore {
    static let key = "activeRules"
    /// At 1 the pair cells stop round-tripping; 4 is the engine maximum.
    static let maxSplitHandsRange = 2...4

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "ActiveRulesStore")

    var rules: BlackjackRules {
        didSet {
            let clean = Self.sanitized(rules)
            if clean != rules { rules = clean }
            persist()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var loaded = BlackjackRules()
        if let data = defaults.data(forKey: Self.key) {
            do {
                loaded = try JSONDecoder().decode(BlackjackRules.self, from: data)
            } catch {
                logger.error("activeRules failed to decode; using defaults: \(error.localizedDescription)")
            }
        }
        self.rules = Self.sanitized(loaded)
    }

    static func sanitized(_ rules: BlackjackRules) -> BlackjackRules {
        var r = rules
        r.maxSplitHands = min(max(r.maxSplitHands, maxSplitHandsRange.lowerBound), maxSplitHandsRange.upperBound)
        return r
    }

    private func persist() {
        do {
            defaults.set(try JSONEncoder().encode(rules), forKey: Self.key)
        } catch {
            logger.error("activeRules failed to encode: \(error.localizedDescription)")
        }
    }
}
