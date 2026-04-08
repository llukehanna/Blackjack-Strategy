import SwiftUI
import SwiftData
import BJSCore

struct SessionLaunch: Identifiable {
    let id = UUID()
    let mode: TrainingMode
    let rules: BlackjackRules
}

@main
struct BJSApp: App {
    @State private var rulesViewModel = RulesViewModel()
    @State private var activeSession: SessionLaunch?

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Practice", systemImage: "suit.spade.fill") {
                    NavigationStack {
                        SessionStartView(onStart: { mode in
                            activeSession = SessionLaunch(
                                mode: mode,
                                rules: rulesViewModel.rules
                            )
                        })
                    }
                }
            }
            .tint(BJSColors.accentGold)
            .environment(rulesViewModel)
            .fullScreenCover(item: $activeSession) { launch in
                TrainerView(mode: launch.mode, rules: launch.rules)
                    .environment(rulesViewModel)
            }
        }
        .modelContainer(for: [TrainingSession.self, SessionDecision.self])
    }
}
