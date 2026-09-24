import BJSCore
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

/// A training session presented full-screen over the tabs.
struct ActiveSession: Identifiable, Equatable {
    let id = UUID()
    let strategy: StrategySessionConfig
}

/// The composition root for navigation: it is the only place that knows which screen
/// each hub route and tab shows, and it presents training sessions full-screen.
struct RootTabView: View {
    @Environment(LastLaunchStore.self) private var lastLaunchStore
    @State private var selection: AppTab = .train
    @State private var activeSession: ActiveSession?

    /// A fixed seed for Strategy sessions (UI tests), or nil.
    private let strategySeed: UInt64?

    init(strategySeed: UInt64? = nil) {
        self.strategySeed = strategySeed
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.train.rawValue, systemImage: AppTab.train.systemImage, value: AppTab.train) {
                HubView(onShowRules: { selection = .settings },
                        onContinue: { launch in continueLast(launch) }) { route in
                    destination(for: route)
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
        .fullScreenCover(item: $activeSession) { session in
            StrategySessionScreen(config: session.strategy, seed: strategySeed) {
                activeSession = nil
            }
        }
    }

    @ViewBuilder
    private func destination(for route: HubRoute) -> some View {
        switch route {
        case .strategy:
            StrategySetupView(initial: lastLaunchStore.lastLaunch?.strategy) { config in
                startStrategy(config)
            }
        case .counting, .shoeSim, .edge:
            PlaceholderScreen(title: route.title)
        }
    }

    private func startStrategy(_ config: StrategySessionConfig) {
        lastLaunchStore.record(.forStrategy(config))
        activeSession = ActiveSession(strategy: config)
    }

    /// Continue relaunches the last module and mode with its last setup, skipping setup.
    private func continueLast(_ launch: LastLaunch) {
        switch launch.module {
        case .strategy:
            if let config = launch.strategy { startStrategy(config) }
        case .countingRC, .countingTC, .shoe:
            break   // Steps 4 and 7 add these modules.
        }
    }
}

private extension View {
    /// Tab bar on `feltDeep` (spec §4: "tab bar base").
    func feltTabBar() -> some View {
        toolbarBackground(FeltColor.feltDeep, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}
