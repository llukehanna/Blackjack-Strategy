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
}
