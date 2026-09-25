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
    @State private var showsCatalogue = false

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            Tab(AppTab.train.rawValue, systemImage: AppTab.train.systemImage, value: AppTab.train) {
                HubView()
            }
            Tab(AppTab.progress.rawValue, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                ComingSoonView(title: "Progress", message: "Coming in Step 6")
            }
            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage, value: AppTab.settings) {
                SettingsView()
            }
        }
        .tint(FeltColor.cream)
        #if DEBUG
        .onAppear { showsCatalogue = showsCatalogueAtLaunch }
        .fullScreenCover(isPresented: $showsCatalogue) {
            FeltCatalogue { showsCatalogue = false }
        }
        #endif
    }
}
