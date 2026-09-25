import Observation

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

/// App-level navigation state shared across features (e.g. the hub header opens Settings).
@Observable
final class AppRouter {
    var selectedTab: AppTab

    init(selectedTab: AppTab = .train) {
        self.selectedTab = selectedTab
    }
}
