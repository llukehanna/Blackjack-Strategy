import BJSCore
import Foundation
import Observation

/// The one app-wide active rule set (spec §3 rule 4), injected through the environment.
///
/// Persisted as JSON `Data` under the `activeRules` key — the same key and type
/// `@AppStorage("activeRules") var data: Data` would use. `@AppStorage` itself cannot
/// live inside an `@Observable` class (it only publishes changes from inside a View),
/// so the store reads and writes `UserDefaults` directly.
@MainActor
@Observable
final class ActiveRulesStore {
    nonisolated static let storageKey = "activeRules"

    private let defaults: UserDefaults
    private var storedRules: BlackjackRules

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storedRules = Self.load(from: defaults)
    }

    /// Setting the rules saves them immediately.
    var rules: BlackjackRules {
        get { storedRules }
        set {
            storedRules = newValue
            defaults.set(RulesCoding.encode(newValue), forKey: Self.storageKey)
        }
    }

    /// The preset these rules equal, or nil for a custom rule set.
    var matchingPreset: RulePreset? { RulePreset.matching(rules) }

    func apply(_ preset: RulePreset) {
        rules = preset.rules
    }

    /// Missing data → defaults. Undecodable data → defaults, logged (spec §6 error handling).
    private static func load(from defaults: UserDefaults) -> BlackjackRules {
        guard let data = defaults.data(forKey: storageKey) else { return BlackjackRules() }
        do {
            return try RulesCoding.decode(data)
        } catch {
            let message = String(describing: error)
            AppLog.settings.error("activeRules failed to decode; using defaults. \(message, privacy: .public)")
            return BlackjackRules()
        }
    }
}
