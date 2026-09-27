import Observation
import BJSCore

/// The card-values self-test (Step 4 spec §4): one card at a time, answer +1 / 0 / −1.
/// Endless and not persisted.
@MainActor
@Observable
final class CardValuesViewModel {
    private(set) var card: Card
    private(set) var answered = 0
    private(set) var correct = 0
    private(set) var streak = 0
    /// Bumps on every correct answer; the view flashes the ✓ toast.
    private(set) var toastCount = 0
    /// The card just answered wrongly. The FeedbackCard shows until NEXT.
    private(set) var mistake: Card?

    @ObservationIgnored private var rng: SeededRandomNumberGenerator

    init(seed: UInt64) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        card = Self.randomCard(using: &rng)
        self.rng = rng
    }

    func answer(_ value: Int) {
        guard mistake == nil else { return }
        answered += 1
        if value == card.rank.hiLoValue {
            correct += 1
            streak += 1
            toastCount += 1
            card = Self.randomCard(using: &rng)
        } else {
            streak = 0
            mistake = card
        }
    }

    /// FeedbackCard NEXT after a mistake.
    func next() {
        guard mistake != nil else { return }
        mistake = nil
        card = Self.randomCard(using: &rng)
    }

    private static func randomCard(using rng: inout SeededRandomNumberGenerator) -> Card {
        Card(rank: Rank.allCases.randomElement(using: &rng)!, suit: Suit.allCases.randomElement(using: &rng)!)
    }
}
