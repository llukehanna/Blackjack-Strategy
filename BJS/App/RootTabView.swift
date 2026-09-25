import SwiftUI

struct RootTabView: View {
    var showsCatalogueAtLaunch = false
    @Environment(AppRouter.self) private var router
    @State private var showsCatalogue = false

    init(showsCatalogueAtLaunch: Bool = false) {
        self.showsCatalogueAtLaunch = showsCatalogueAtLaunch
        #if DEBUG
        _showsCatalogue = State(initialValue: showsCatalogueAtLaunch)
        #endif
    }

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
        .fullScreenCover(isPresented: $showsCatalogue) {
            FeltCatalogue { showsCatalogue = false }
        }
        #endif
    }
}
