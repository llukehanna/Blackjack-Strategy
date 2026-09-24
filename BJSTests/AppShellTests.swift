import Testing
@testable import BJS

@MainActor
struct AppShellTests {

    @Test("App has exactly three tabs: Train, Progress, Settings")
    func tabsInOrder() {
        #expect(AppTab.allCases.map(\.rawValue) == ["Train", "Progress", "Settings"])
    }

    @Test("Every tab has an SF Symbol")
    func tabsHaveIcons() {
        for tab in AppTab.allCases {
            #expect(!tab.systemImage.isEmpty)
        }
    }

    @Test("Hub tiles: Strategy, Counting, Shoe Sim, Edge")
    func hubTiles() {
        #expect(HubRoute.allCases.map(\.title) == ["Strategy", "Counting", "Shoe Sim", "Edge"])
        #expect(HubRoute.allCases.allSatisfy { !$0.subtitle.isEmpty })
    }
}

@Suite("LaunchConfiguration")
struct LaunchConfigurationTests {

    @Test("Plain launch: not UI testing, no gallery")
    func plain() {
        let config = LaunchConfiguration(environment: [:])
        #expect(!config.isUITesting)
        #expect(config.galleryPageName == nil)
    }

    @Test("UI-test launch reads both switches")
    func uiTesting() {
        let config = LaunchConfiguration(environment: ["BJS_UI_TESTING": "1", "BJS_GALLERY_PAGE": "cards"])
        #expect(config.isUITesting)
        #expect(config.galleryPageName == "cards")
    }

    @Test("UI testing uses a wiped, separate defaults suite")
    func uiDefaults() {
        let config = LaunchConfiguration(environment: ["BJS_UI_TESTING": "1"])
        let first = config.makeUserDefaults()
        first.set(true, forKey: "leftover")
        let second = config.makeUserDefaults()
        #expect(second.object(forKey: "leftover") == nil)
    }
}
