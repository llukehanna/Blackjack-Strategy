/// Which hand categories a strategy session deals.
public enum HandFilter: String, CaseIterable, Sendable, Codable {
    case all, hard, soft, pairs

    public func includes(_ type: HandType) -> Bool {
        switch self {
        case .all: return true
        case .hard: return type == .hard
        case .soft: return type == .soft
        case .pairs: return type == .pair
        }
    }
}

/// One strategy decision "cell": hand category x player value x dealer upcard.
///
/// - `playerValue`: the hard or soft total; for pairs, the rank value 2...11 (11 = aces).
/// - `dealerUpcard`: 2...11, where 10 covers T/J/Q/K and 11 = ace.
public struct TrainingCell: Hashable, Sendable, Codable {
    public let handType: HandType
    public let playerValue: Int
    public let dealerUpcard: Int

    public init(handType: HandType, playerValue: Int, dealerUpcard: Int) {
        self.handType = handType
        self.playerValue = playerValue
        self.dealerUpcard = dealerUpcard
    }

    /// Classifies a decision. A two-card pair counts as `.pair` only while splitting is legal.
    public init(spot: DecisionSpot) {
        let hand = spot.hand
        let upcard = spot.dealerUpcard == .ace ? 11 : spot.dealerUpcard.blackjackValue
        if hand.isPair && spot.legalActions.contains(.split) {
            let rank = hand.cards[0].rank
            self.init(handType: .pair, playerValue: rank == .ace ? 11 : rank.blackjackValue,
                      dealerUpcard: upcard)
        } else if hand.isSoft {
            self.init(handType: .soft, playerValue: hand.total, dealerUpcard: upcard)
        } else {
            self.init(handType: .hard, playerValue: hand.total, dealerUpcard: upcard)
        }
    }

    /// Every trainable two-card starting cell: hard 5-20, soft 13-20, pairs 2-A, vs upcards 2-A.
    public static let all: [TrainingCell] = {
        let upcards = Array(2...11)
        var cells: [TrainingCell] = []
        for value in 5...20 {
            for up in upcards { cells.append(TrainingCell(handType: .hard, playerValue: value, dealerUpcard: up)) }
        }
        for value in 13...20 {
            for up in upcards { cells.append(TrainingCell(handType: .soft, playerValue: value, dealerUpcard: up)) }
        }
        for value in 2...11 {
            for up in upcards { cells.append(TrainingCell(handType: .pair, playerValue: value, dealerUpcard: up)) }
        }
        return cells
    }()

    public static func cells(matching filter: HandFilter) -> [TrainingCell] {
        all.filter { filter.includes($0.handType) }
    }
}
