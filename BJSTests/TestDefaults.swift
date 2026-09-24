import Foundation

/// A throwaway `UserDefaults` suite so tests never touch `.standard` or each other.
enum TestDefaults {
    static func make() -> UserDefaults {
        let name = "BJSTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else {
            preconditionFailure("could not create UserDefaults suite \(name)")
        }
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
