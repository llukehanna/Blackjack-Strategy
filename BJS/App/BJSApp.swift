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
            .tint(BJSColors.accentGold) // #warning("Phase 7: BJSApp uses placeholder token — will be re-skinned in a later phase")
            .environment(rulesViewModel)
        }
        .modelContainer(for: [TrainingSession.self, SessionDecision.self])
    }
}
