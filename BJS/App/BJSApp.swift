import SwiftUI
import SwiftData

@main
struct BJSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TrainingSession.self, SessionDecision.self])
    }
}

/// Temporary root view -- replaced in Plan 03 with TabView + NavigationStack
struct ContentView: View {
    var body: some View {
        Text("BJS - Strategy Trainer")
            .font(.title2)
    }
}
