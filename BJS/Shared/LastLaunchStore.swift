import Foundation
import Observation

/// The hub's Continue target, persisted as JSON `Data` under the `lastLaunch` key
/// (the same key and type `@AppStorage("lastLaunch") var data: Data` would use).
/// Nil until the first session starts, so Continue is hidden on first launch.
@MainActor
@Observable
final class LastLaunchStore {
    nonisolated static let storageKey = "lastLaunch"

    private let defaults: UserDefaults
    private(set) var lastLaunch: LastLaunch?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lastLaunch = Self.load(from: defaults)
    }

    /// Called when a session starts (from setup or from Continue).
    func record(_ launch: LastLaunch) {
        lastLaunch = launch
        defaults.set(LastLaunch.encode(launch), forKey: Self.storageKey)
    }

    /// Missing → nil. Undecodable → nil, logged (Continue stays hidden until the next session).
    private static func load(from defaults: UserDefaults) -> LastLaunch? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        do {
            return try LastLaunch.decode(data)
        } catch {
            let message = String(describing: error)
            AppLog.settings.error("lastLaunch failed to decode; hiding Continue. \(message, privacy: .public)")
            return nil
        }
    }
}
