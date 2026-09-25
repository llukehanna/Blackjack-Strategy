import Foundation

/// Process launch arguments used by UI tests and design screenshots.
struct LaunchConfiguration {
    /// In-memory SwiftData store and an empty UserDefaults suite.
    let isUITesting: Bool
    let startTab: AppTab?
    /// DEBUG builds only: present the Felt catalogue at launch.
    let showsCatalogue: Bool

    init(arguments: [String]) {
        isUITesting = arguments.contains("-uiTesting")
        showsCatalogue = arguments.contains("-showCatalogue")
        if let index = arguments.firstIndex(of: "-startTab"), index + 1 < arguments.count {
            startTab = AppTab(rawValue: arguments[index + 1].capitalized)
        } else {
            startTab = nil
        }
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
