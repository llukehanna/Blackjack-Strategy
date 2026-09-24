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
            rootView
                .environment(rulesStore)
                .environment(preferences)
                .preferredColorScheme(.dark)
                .tint(FeltColor.cream)
        }
        .modelContainer(modelContainer)
    }

    #if DEBUG
    @ViewBuilder
    private var rootView: some View {
        if let name = launch.galleryPageName, let page = GalleryPage(rawValue: name) {
            ComponentGalleryView(page: page)
        } else {
            RootTabView()
        }
    }
    #else
    private var rootView: some View {
        RootTabView()
    }
    #endif
}
