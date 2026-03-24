/// The possible player actions in blackjack.
public enum Action: String, CaseIterable, Sendable, Codable, Hashable {
    case hit
    case stand
    case double
    case split
    case surrender
}
