import SwiftUI

/// The three top-level tabs (spec §5 Navigation).
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

/// The composition root for navigation: it is the only place that knows which screen
/// each hub route and tab shows. Module screens arrive in Steps 3–7.
struct RootTabView: View {
    @State private var selection: AppTab = .train

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.train.rawValue, systemImage: AppTab.train.systemImage, value: AppTab.train) {
                HubView(onShowRules: { selection = .settings }) { route in
                    PlaceholderScreen(title: route.title)
                }
                .feltTabBar()
            }
            Tab(AppTab.progress.rawValue, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                PlaceholderScreen(title: AppTab.progress.rawValue)
                    .feltTabBar()
            }
            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage, value: AppTab.settings) {
                SettingsView()
                    .feltTabBar()
            }
        }
        .tint(FeltColor.cream)
    }
}

private extension View {
    /// Tab bar on `feltDeep` (spec §4: "tab bar base").
    func feltTabBar() -> some View {
        toolbarBackground(FeltColor.feltDeep, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}
