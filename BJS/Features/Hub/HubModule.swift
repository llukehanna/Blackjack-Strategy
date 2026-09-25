/// The hub's module tiles. Each opens a placeholder until its build step (parent spec §8).
enum HubModule: String, CaseIterable, Identifiable {
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
