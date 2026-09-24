/// The hub's module tiles, in display order. The App layer decides what each route shows,
/// so the Hub never references another feature (spec §3 rule 5).
enum HubRoute: String, CaseIterable, Identifiable, Hashable, Sendable {
    case strategy
    case counting
    case shoeSim
    case edge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strategy: return "Strategy"
        case .counting: return "Counting"
        case .shoeSim: return "Shoe Sim"
        case .edge: return "Edge"
        }
    }

    var subtitle: String {
        switch self {
        case .strategy: return "Basic strategy drills"
        case .counting: return "Hi-Lo running and true count"
        case .shoeSim: return "Play a shoe, keep the count"
        case .edge: return "House edge for any rules"
        }
    }
}
