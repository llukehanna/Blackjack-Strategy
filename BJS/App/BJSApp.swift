import os
import SwiftData
import SwiftUI

@main
struct BJSApp: App {
    private let launch = LaunchConfiguration.current
    private let container: ModelContainer
    @State private var rulesStore: ActiveRulesStore
    @State private var preferences: PreferencesStore
    @State private var sessionStore: SessionStore
    @State private var router: AppRouter

    init() {
        let launch = LaunchConfiguration.current
        let container: ModelContainer
        do {
            container = try BJSModelContainer.make(inMemory: launch.isUITesting)
        } catch {
            // Never crash on a bad store (parent spec §6): run this launch in memory.
            Logger(subsystem: "com.bjs.app", category: "BJSApp")
                .error("Persistent store failed to open; using in-memory store: \(error.localizedDescription)")
            container = try! BJSModelContainer.make(inMemory: true)
        }
        self.container = container
        let defaults = launch.makeUserDefaults()
        _rulesStore = State(initialValue: ActiveRulesStore(defaults: defaults))
        _preferences = State(initialValue: PreferencesStore(defaults: defaults))
        _sessionStore = State(initialValue: SessionStore(context: container.mainContext))
        _router = State(initialValue: AppRouter(selectedTab: launch.startTab ?? .train))
        FeltTabBarAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(showsCatalogueAtLaunch: launch.showsCatalogue)
                .environment(rulesStore)
                .environment(preferences)
                .environment(sessionStore)
                .environment(router)
                .modelContainer(container)
                .preferredColorScheme(.dark)
        }
    }
}
