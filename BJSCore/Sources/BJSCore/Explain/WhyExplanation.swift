import Foundation

/// Categorizes a player's hand for strategy explanation purposes.
/// BJSCore models pair/soft/hard via flags on `BlackjackHand`; this enum
/// flattens that into a single tag for switching in `WhyExplanation`.
public enum HandType: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case hard
    case soft
    case pair
}

/// Pure-domain context describing a single decision moment, used by
/// `WhyExplanation.explain` to produce a learner-facing rationale string.
///
/// This type is intentionally view-free and Sendable so it can be passed
/// across actor boundaries (e.g. to a SwiftUI sheet) without UI coupling.
public struct WhyContext: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let handTotal: Int
    public let handType: HandType
    public let pairRank: Rank?           // only meaningful when handType == .pair
    public let dealerUpCard: Rank
    public let userAction: Action
    public let correctAction: Action
    public let rules: BlackjackRules

    public init(
        id: UUID = UUID(),
        handTotal: Int,
        handType: HandType,
        pairRank: Rank? = nil,
        dealerUpCard: Rank,
        userAction: Action,
        correctAction: Action,
        rules: BlackjackRules
    ) {
        self.id = id
        self.handTotal = handTotal
        self.handType = handType
        self.pairRank = pairRank
        self.dealerUpCard = dealerUpCard
        self.userAction = userAction
        self.correctAction = correctAction
        self.rules = rules
    }
}

/// Builds a 1–3 sentence explanation of why `correctAction` is the right
/// move for a given `WhyContext`. Pure function, no side effects, no I/O.
///
/// The strategy here is template-based: switch on `(handType, correctAction)`
/// to pick a family, then refine by total / dealer strength. The function
/// is total — every (handType, action) combination produces a non-empty
/// bounded string (>= 30, < 400 characters).
public enum WhyExplanation {

    public static func explain(_ context: WhyContext) -> String {
        let raw = template(for: context)
        // Defensive: never return empty, never exceed budget.
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 30 {
            return pad(trimmed, context: context)
        }
        if trimmed.count >= 400 {
            return String(trimmed.prefix(399))
        }
        return trimmed
    }

    // MARK: - Template selection

    private static func template(for c: WhyContext) -> String {
        let total = c.handTotal
        let up = upCardName(c.dealerUpCard)
        let dealerWeak = isDealerWeak(c.dealerUpCard)
        let dealerStrong = isDealerStrong(c.dealerUpCard)

        // Early surrender vs an Ace or 10: the reason is the dealer's unrevealed blackjack,
        // not that the hand "loses more than half the time" (e.g. hard 7 vs Ace).
        if c.correctAction == .surrender && c.rules.surrenderRule == .early
            && canMakeBlackjack(c.dealerUpCard) {
            let hand: String
            switch c.handType {
            case .hard: hand = "Hard \(total)"
            case .soft: hand = "Soft \(total)"
            case .pair: hand = "Pair of \(pairRankName(c.pairRank))s"
            }
            return "\(hand) vs dealer's \(up): Early surrender lets you give up half your bet before the dealer's blackjack is known. Counting the chance the dealer already has blackjack, playing on loses more than half a bet here."
        }

        switch (c.handType, c.correctAction) {

        // MARK: Hard totals
        case (.hard, .stand):
            if total >= 17 {
                return "Hard \(total): you're already in a strong stand range — hitting risks busting for almost no upside."
            }
            if total >= 12 && dealerWeak {
                return "Hard \(total) vs dealer's \(up): the dealer is likely to bust with a weak up card, so standing lets the dealer beat themselves."
            }
            return "Hard \(total) vs dealer's \(up): standing is the percentage play in this spot — taking another card hurts you more often than it helps."

        case (.hard, .hit):
            if total <= 11 {
                return "Hard \(total): you can't bust on the next card, so always take a free card to improve your total."
            }
            if total <= 16 && dealerStrong {
                return "Hard \(total) vs dealer's \(up): the dealer's strong up card will likely beat you if you stand, so hitting is the lesser-of-two-evils play."
            }
            return "Hard \(total) vs dealer's \(up): hitting gives you the best chance to reach a competitive total without giving up the hand."

        case (.hard, .double):
            return "Hard \(total) vs dealer's \(up): doubling capitalizes on the dealer's weak up card — one well-placed extra card swings the math in your favor."

        case (.hard, .split):
            // Hard + split shouldn't normally happen, but cover the case.
            return "Hard \(total): the strategy table treats this as a split situation — separating the cards gives you two fresh starts instead of one losing total."

        case (.hard, .surrender):
            return "Hard \(total) vs dealer's \(up): this hand loses more than half the time. Surrendering takes the guaranteed half-loss instead of bleeding more equity."

        // MARK: Soft totals
        case (.soft, .hit):
            if total == 18 {
                return "Soft 18 vs dealer's \(up): the dealer's \(up) is strong enough to outdraw 18, and because you can't bust on the next card, hitting gives you a free shot at upgrading."
            }
            return "Soft \(total) vs dealer's \(up): you can't bust on the next card, so hitting only improves your hand — there is zero downside to taking another card here."

        case (.soft, .stand):
            if total >= 19 {
                return "Soft \(total): already a strong total — locking it in beats risking a worse one for a marginal upgrade."
            }
            return "Soft \(total) vs dealer's \(up): the dealer is unlikely to outdraw you, so standing preserves a winning total."

        case (.soft, .double):
            return "Soft \(total) vs dealer's \(up): double for value — you can't bust on the next card and the dealer's weak up card means the extra bet has positive expectation."

        case (.soft, .split):
            return "Soft \(total): the table calls for splitting here — turning a marginal soft total into two hands starting fresh is the higher-EV move."

        case (.soft, .surrender):
            return "Soft \(total) vs dealer's \(up): rare, but the math says half a bet back beats playing out a losing hand."

        // MARK: Pairs
        case (.pair, .split):
            let rankName = pairRankName(c.pairRank)
            if c.pairRank == .ace {
                return "Pair of Aces: soft 12 is a weak total. Splitting turns one mediocre hand into two hands each starting with an ace — the strongest possible starting card."
            }
            if c.pairRank == .eight {
                return "Pair of 8s: hard 16 is a losing hand against almost any dealer up card. Splitting gives you two hands each starting with 8 — strictly better than stuck on 16."
            }
            return "Pair of \(rankName)s vs dealer's \(up): splitting turns a mediocre combined total into two stronger starting hands and exploits the dealer's weakness."

        case (.pair, .stand):
            if c.pairRank == .ten || c.pairRank == .jack || c.pairRank == .queen || c.pairRank == .king {
                return "Pair of 10s: 20 is one of the strongest totals in the game — never break a winning hand chasing a marginal upgrade."
            }
            return "Pair of \(pairRankName(c.pairRank))s: standing on this combined total beats splitting it into two weaker hands."

        case (.pair, .hit):
            return "Pair of \(pairRankName(c.pairRank))s: don't split here — you'd be turning one okay hand into two bad ones. Hitting the combined total is the higher-EV play."

        case (.pair, .double):
            return "Pair of \(pairRankName(c.pairRank))s: the combined total is a doubling spot against the dealer's \(up). Take the extra bet rather than splitting into two weaker starts."

        case (.pair, .surrender):
            return "Pair of \(pairRankName(c.pairRank))s vs dealer's \(up): both starting cards point to a losing hand — surrender locks in half a bet instead of the full loss."
        }
    }

    // MARK: - Helpers

    private static func isDealerWeak(_ rank: Rank) -> Bool {
        switch rank {
        case .two, .three, .four, .five, .six: return true
        default: return false
        }
    }

    private static func canMakeBlackjack(_ rank: Rank) -> Bool {
        switch rank {
        case .ace, .ten, .jack, .queen, .king: return true
        default: return false
        }
    }

    private static func isDealerStrong(_ rank: Rank) -> Bool {
        switch rank {
        case .seven, .eight, .nine, .ten, .jack, .queen, .king, .ace: return true
        default: return false
        }
    }

    private static func upCardName(_ rank: Rank) -> String {
        switch rank {
        case .ace: return "Ace"
        case .king, .queen, .jack, .ten: return "10"
        default: return String(rank.blackjackValue)
        }
    }

    private static func pairRankName(_ rank: Rank?) -> String {
        guard let rank = rank else { return "cards" }
        switch rank {
        case .ace: return "Ace"
        case .king: return "King"
        case .queen: return "Queen"
        case .jack: return "Jack"
        default: return String(rank.blackjackValue)
        }
    }

    /// Defensive padding so a future template that goes too short still
    /// satisfies the >= 30 character contract. Should rarely fire.
    private static func pad(_ short: String, context c: WhyContext) -> String {
        let base = short.isEmpty ? "Correct play" : short
        return "\(base): the strategy table favors \(c.correctAction.rawValue) for this hand against dealer's \(upCardName(c.dealerUpCard))."
    }
}
