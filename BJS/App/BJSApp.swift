import SwiftData
import SwiftUI

@main
struct BJSApp: App {
    private let launch: LaunchConfiguration
    private let modelContainer: ModelContainer
    @State private var rulesStore: ActiveRulesStore
    @State private var preferences: Preferences

    init() {
        let launch = LaunchConfiguration.current
        let defaults = launch.makeUserDefaults()
        self.launch = launch
        self.modelContainer = PersistenceController.makeAppContainer(inMemory: launch.isUITesting)
        self._rulesStore = State(initialValue: ActiveRulesStore(defaults: defaults))
        self._preferences = State(initialValue: Preferences(defaults: defaults))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(rulesStore)
                .environment(preferences)
                .preferredColorScheme(.dark)
                .tint(FeltColor.cream)
        }
        .modelContainer(modelContainer)
    }
}
