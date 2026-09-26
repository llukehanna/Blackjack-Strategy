import Foundation

/// Process launch arguments used by UI tests and design screenshots.
struct LaunchConfiguration {
    /// In-memory SwiftData store and an empty UserDefaults suite.
    let isUITesting: Bool
    let startTab: AppTab?
    /// DEBUG builds only: present the Felt catalogue at launch.
    let showsCatalogue: Bool
    /// UI testing only: overrides the Strategy session length (hands).
    let strategyLength: Int?
    /// UI testing only: seeds the Strategy trainer's random number generator.
    let seed: UInt64?

    init(arguments: [String]) {
        isUITesting = arguments.contains("-uiTesting")
        showsCatalogue = arguments.contains("-showCatalogue")
        if let index = arguments.firstIndex(of: "-startTab"), index + 1 < arguments.count {
            startTab = AppTab(rawValue: arguments[index + 1].capitalized)
        } else {
            startTab = nil
        }
        func value(after flag: String) -> String? {
            guard let i = arguments.firstIndex(of: flag), i + 1 < arguments.count else { return nil }
            return arguments[i + 1]
        }
        strategyLength = isUITesting ? value(after: "-strategyLength").flatMap { Int($0) } : nil
        seed = isUITesting ? value(after: "-seed").flatMap { UInt64($0) } : nil
    }

    static let current = LaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)

    /// Standard defaults normally; a fresh, empty suite under UI testing.
    func makeUserDefaults() -> UserDefaults {
        guard isUITesting else { return .standard }
        let name = "BJSUITests"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
