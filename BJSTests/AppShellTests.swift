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

    @Test("Router starts on Train")
    func routerDefault() {
        #expect(AppRouter().selectedTab == .train)
    }

    @Test("Launch arguments: none")
    func launchDefaults() {
        let config = LaunchConfiguration(arguments: ["BJS"])
        #expect(!config.isUITesting)
        #expect(config.startTab == nil)
        #expect(!config.showsCatalogue)
    }

    @Test("Launch arguments: UI testing, start tab, catalogue")
    func launchArguments() {
        let config = LaunchConfiguration(arguments: ["BJS", "-uiTesting", "-startTab", "settings", "-showCatalogue"])
        #expect(config.isUITesting)
        #expect(config.startTab == .settings)
        #expect(config.showsCatalogue)
    }

    @Test("Unknown or missing start tab is ignored")
    func badStartTab() {
        #expect(LaunchConfiguration(arguments: ["BJS", "-startTab", "casino"]).startTab == nil)
        #expect(LaunchConfiguration(arguments: ["BJS", "-startTab"]).startTab == nil)
    }
}
