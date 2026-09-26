import Foundation

/// The trainable areas the hub launches (parent spec §5). Shared so the App layer can route
/// launches without the hub knowing about any feature.
enum AppModule: String, CaseIterable, Identifiable {
    case strategy, counting, shoe, edge

    var id: Self { self }

    var title: String {
        switch self {
        case .strategy: return "Strategy"
        case .counting: return "Counting"
        case .shoe: return "Shoe Sim"
        case .edge: return "Edge"
        }
    }

    var subtitle: String {
        switch self {
        case .strategy: return "Basic strategy drills"
        case .counting: return "Hi-Lo running and true count"
        case .shoe: return "Play and count a full shoe"
        case .edge: return "House edge for any rules"
        }
    }

    /// The build step that delivers this module.
    var step: Int {
        switch self {
        case .strategy: return 3
        case .counting: return 4
        case .shoe: return 7
        case .edge: return 5
        }
    }
}

/// A request to present a module full-screen. `setup` is the module's own encoded setup
/// (Continue); nil opens the module's setup screen. Every launch has a fresh id.
struct ModuleLaunch: Identifiable, Equatable {
    let id = UUID()
    let module: AppModule
    let setup: Data?
}
