import SwiftUI
import SwiftData

@main
struct BJSApp: App {
    @State private var rulesViewModel = RulesViewModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Practice", systemImage: "suit.spade.fill") {
                    NavigationStack {
                        SessionStartView()
                    }
                }
            }
            .environment(rulesViewModel)
        }
        .modelContainer(for: [TrainingSession.self, SessionDecision.self])
    }
}
