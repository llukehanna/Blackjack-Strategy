import SwiftUI
import BJSCore

struct CardView: View {
    let card: Card?
    let faceDown: Bool
    let width: CGFloat

    init(card: Card, width: CGFloat) {
        self.card = card
        self.faceDown = false
        self.width = width
    }

    init(card: Card, faceDown: Bool, width: CGFloat) {
        self.card = card
        self.faceDown = faceDown
        self.width = width
    }

    init(faceDown: Bool, width: CGFloat) {
        self.card = nil
        self.faceDown = faceDown
        self.width = width
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width * 7.0 / 5.0)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .shadow(
                color: Elevation.card.color,
                radius: Elevation.card.radius,
                x: Elevation.card.x,
                y: Elevation.card.y
            )
            .accessibilityLabel(accessibilityText)
    }

    // MARK: - Asset mapping

    var assetName: String {
        if faceDown || card == nil { return "card_back" }
        return "\(CardView.rankName(card!.rank))_of_\(CardView.suitName(card!.suit))"
    }

    static func rankName(_ r: Rank) -> String {
        switch r {
        case .ace:   return "ace"
        case .two:   return "2"
        case .three: return "3"
        case .four:  return "4"
        case .five:  return "5"
        case .six:   return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine:  return "9"
        case .ten:   return "10"
        case .jack:  return "jack"
        case .queen: return "queen"
        case .king:  return "king"
        }
    }

    static func suitName(_ s: Suit) -> String {
        switch s {
        case .clubs:    return "clubs"
        case .diamonds: return "diamonds"
        case .hearts:   return "hearts"
        case .spades:   return "spades"
        }
    }

    private var accessibilityText: String {
        if faceDown || card == nil { return "Face-down card" }
        return "\(CardView.rankName(card!.rank).capitalized) of \(CardView.suitName(card!.suit).capitalized)"
    }
}
