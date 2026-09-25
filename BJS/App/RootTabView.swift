import SwiftUI

/// The three top-level tabs.
enum AppTab: String, CaseIterable, Identifiable {
    case train = "Train"
    case progress = "Progress"
    case settings = "Settings"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .train: return "suit.spade.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        }
    }
}

struct RootTabView: View {
    var showsCatalogueAtLaunch = false
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            Tab(AppTab.train.rawValue, systemImage: AppTab.train.systemImage, value: AppTab.train) {
                HubPlaceholder()
            }
            Tab(AppTab.progress.rawValue, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                ComingSoonView(title: "Progress", message: "Coming in Step 6")
            }
            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage, value: AppTab.settings) {
                SettingsPlaceholder()
            }
        }
        .tint(FeltColor.cream)
    }
}

/// Replaced by `HubView` in Task 12.
private struct HubPlaceholder: View {
    var body: some View { ComingSoonView(title: "Train", message: "Hub arrives in Task 12") }
}

/// Replaced by `SettingsView` in Task 14.
private struct SettingsPlaceholder: View {
    var body: some View { ComingSoonView(title: "Settings", message: "Settings arrive in Task 14") }
}
