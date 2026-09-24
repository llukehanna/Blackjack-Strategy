import BJSCore
import Foundation
import Observation

/// User preferences (spec §5 Settings, §6 `@AppStorage` keys), injected through the environment.
///
/// Stored in `UserDefaults` under the spec's key names with `@AppStorage`-compatible
/// types (Double, String raw value, Int, Bool). Invalid stored values fall back to the
/// default and are logged.
@MainActor
@Observable
final class Preferences {
    enum Key {
        static let speedTimerSeconds = "speedTimerSeconds"
        static let trueCountConvention = "trueCountConvention"
        static let shoeCheckFrequency = "shoeCheckFrequency"
        static let hapticsEnabled = "hapticsEnabled"
    }

    nonisolated static let defaultSpeedTimerSeconds = 3.0
    nonisolated static let speedTimerRange: ClosedRange<Double> = 1...5
    /// Picker choices: 1.0 s to 5.0 s in 0.5 s steps.
    nonisolated static let speedTimerOptions: [Double] = Array(stride(from: 1.0, through: 5.0, by: 0.5))

    nonisolated static let defaultShoeCheckEveryRounds = 4
    nonisolated static let shoeCheckRange: ClosedRange<Int> = 2...8
    /// Picker choices: a count check about once every N rounds.
    nonisolated static let shoeCheckOptions: [Int] = [2, 3, 4, 6, 8]

    private let defaults: UserDefaults
    private var storedSpeedTimerSeconds: Double
    private var storedTrueCountConvention: TrueCountConvention
    private var storedShoeCheckEveryRounds: Int
    private var storedHapticsEnabled: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let seconds = defaults.object(forKey: Key.speedTimerSeconds) as? Double {
            storedSpeedTimerSeconds = Self.clampedSpeedTimer(seconds)
        } else {
            storedSpeedTimerSeconds = Self.defaultSpeedTimerSeconds
        }

        if let raw = defaults.string(forKey: Key.trueCountConvention) {
            if let convention = TrueCountConvention(rawValue: raw) {
                storedTrueCountConvention = convention
            } else {
                AppLog.settings.error("Unknown trueCountConvention '\(raw, privacy: .public)'; using exact.")
                storedTrueCountConvention = .exact
            }
        } else {
            storedTrueCountConvention = .exact
        }

        if let rounds = defaults.object(forKey: Key.shoeCheckFrequency) as? Int,
           Self.shoeCheckRange.contains(rounds) {
            storedShoeCheckEveryRounds = rounds
        } else {
            storedShoeCheckEveryRounds = Self.defaultShoeCheckEveryRounds
        }

        storedHapticsEnabled = defaults.object(forKey: Key.hapticsEnabled) as? Bool ?? true
    }

    /// Speed-mode countdown per decision, 1–5 s (default 3.0).
    var speedTimerSeconds: Double {
        get { storedSpeedTimerSeconds }
        set {
            let value = Self.clampedSpeedTimer(newValue)
            storedSpeedTimerSeconds = value
            defaults.set(value, forKey: Key.speedTimerSeconds)
        }
    }

    /// How true-count answers are graded (default Exact).
    var trueCountConvention: TrueCountConvention {
        get { storedTrueCountConvention }
        set {
            storedTrueCountConvention = newValue
            defaults.set(newValue.rawValue, forKey: Key.trueCountConvention)
        }
    }

    /// Shoe Sim asks for the count about once every this many rounds (default 4).
    var shoeCheckEveryRounds: Int {
        get { storedShoeCheckEveryRounds }
        set {
            let value = min(max(newValue, Self.shoeCheckRange.lowerBound), Self.shoeCheckRange.upperBound)
            storedShoeCheckEveryRounds = value
            defaults.set(value, forKey: Key.shoeCheckFrequency)
        }
    }

    var hapticsEnabled: Bool {
        get { storedHapticsEnabled }
        set {
            storedHapticsEnabled = newValue
            defaults.set(newValue, forKey: Key.hapticsEnabled)
        }
    }

    private nonisolated static func clampedSpeedTimer(_ seconds: Double) -> Double {
        min(max(seconds, speedTimerRange.lowerBound), speedTimerRange.upperBound)
    }
}
