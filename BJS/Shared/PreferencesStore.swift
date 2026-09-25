import Foundation
import Observation
import os
import BJSCore

/// What the hub's Continue button relaunches. Each feature encodes its own `setup` (Step 3+).
struct LastLaunch: Codable, Equatable {
    var module: TrainingModule
    var mode: String?
    var setup: Data
}

/// User preferences (parent spec §5 Settings, Step 2 spec §4), persisted in UserDefaults.
@Observable
final class PreferencesStore {
    enum Key {
        static let speedTimerSeconds = "speedTimerSeconds"
        static let trueCountConvention = "trueCountConvention"
        static let shoeCheckFrequency = "shoeCheckFrequency"
        static let hapticsEnabled = "hapticsEnabled"
        static let lastLaunch = "lastLaunch"
    }

    static let speedTimerRange = 1.0...5.0
    static let speedTimerStep = 0.5
    static let defaultSpeedTimer = 3.0
    static let shoeCheckRange = 2...8
    static let defaultShoeCheck = 4

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let logger = Logger(subsystem: "com.bjs.app", category: "PreferencesStore")

    var speedTimerSeconds: Double {
        didSet {
            let clean = Self.clampSpeedTimer(speedTimerSeconds)
            if clean != speedTimerSeconds { speedTimerSeconds = clean }
            defaults.set(speedTimerSeconds, forKey: Key.speedTimerSeconds)
        }
    }

    var trueCountConvention: TrueCountConvention {
        didSet { defaults.set(trueCountConvention.rawValue, forKey: Key.trueCountConvention) }
    }

    /// A Shoe Sim count check comes about once every this many rounds.
    var shoeCheckFrequency: Int {
        didSet {
            let clean = Self.clampShoeCheck(shoeCheckFrequency)
            if clean != shoeCheckFrequency { shoeCheckFrequency = clean }
            defaults.set(shoeCheckFrequency, forKey: Key.shoeCheckFrequency)
        }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.hapticsEnabled) }
    }

    var lastLaunch: LastLaunch? {
        didSet { persistLastLaunch() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let speed = defaults.object(forKey: Key.speedTimerSeconds) as? Double ?? Self.defaultSpeedTimer
        self.speedTimerSeconds = Self.clampSpeedTimer(speed)
        self.trueCountConvention = defaults.string(forKey: Key.trueCountConvention)
            .flatMap(TrueCountConvention.init(rawValue:)) ?? .exact
        let shoe = defaults.object(forKey: Key.shoeCheckFrequency) as? Int ?? Self.defaultShoeCheck
        self.shoeCheckFrequency = Self.clampShoeCheck(shoe)
        self.hapticsEnabled = defaults.object(forKey: Key.hapticsEnabled) as? Bool ?? true
        self.lastLaunch = defaults.data(forKey: Key.lastLaunch)
            .flatMap { try? JSONDecoder().decode(LastLaunch.self, from: $0) }
    }

    static func clampSpeedTimer(_ seconds: Double) -> Double {
        let snapped = (seconds / speedTimerStep).rounded() * speedTimerStep
        return min(max(snapped, speedTimerRange.lowerBound), speedTimerRange.upperBound)
    }

    static func clampShoeCheck(_ rounds: Int) -> Int {
        min(max(rounds, shoeCheckRange.lowerBound), shoeCheckRange.upperBound)
    }

    private func persistLastLaunch() {
        guard let lastLaunch else {
            defaults.removeObject(forKey: Key.lastLaunch)
            return
        }
        do {
            defaults.set(try JSONEncoder().encode(lastLaunch), forKey: Key.lastLaunch)
        } catch {
            logger.error("lastLaunch failed to encode: \(error.localizedDescription)")
        }
    }
}
