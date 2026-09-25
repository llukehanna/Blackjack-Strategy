import Observation

/// App-level navigation state shared across features (e.g. the hub header opens Settings).
@Observable
final class AppRouter {
    var selectedTab: AppTab

    init(selectedTab: AppTab = .train) {
        self.selectedTab = selectedTab
    }
}
