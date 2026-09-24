import Foundation

/// Launch-time switches read from the process environment. UI tests set these through
/// `XCUIApplication.launchEnvironment`.
struct LaunchConfiguration: Equatable, Sendable {
    /// "1" → in-memory SwiftData store and a wiped, separate UserDefaults suite.
    static let uiTestingKey = "BJS_UI_TESTING"
    /// A `GalleryPage` raw value → DEBUG builds show that component-gallery page instead of the app.
    static let galleryPageKey = "BJS_GALLERY_PAGE"
    static let uiTestingDefaultsSuite = "com.bjs.app.uitesting"

    let isUITesting: Bool
    let galleryPageName: String?

    init(environment: [String: String]) {
        isUITesting = environment[Self.uiTestingKey] == "1"
        galleryPageName = environment[Self.galleryPageKey]
    }

    static var current: LaunchConfiguration {
        LaunchConfiguration(environment: ProcessInfo.processInfo.environment)
    }

    /// `.standard` normally; a freshly wiped suite under UI testing, so every UI test starts clean.
    func makeUserDefaults() -> UserDefaults {
        guard isUITesting, let defaults = UserDefaults(suiteName: Self.uiTestingDefaultsSuite) else {
            return .standard
        }
        defaults.removePersistentDomain(forName: Self.uiTestingDefaultsSuite)
        return defaults
    }
}
