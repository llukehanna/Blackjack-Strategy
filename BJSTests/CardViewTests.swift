import Testing
import SwiftUI
import UIKit
@testable import BJS
import BJSCore

@MainActor
struct CardViewTests {
    @Test func renderAllCardsNoCrash() {
        for rank in Rank.allCases {
            for suit in Suit.allCases {
                let card = Card(rank: rank, suit: suit)
                let view = CardView(card: card).frame(width: 88, height: 123)
                let host = UIHostingController(rootView: view)
                host.view.layoutIfNeeded()
                #expect(host.view.bounds.width > 0)
            }
        }
    }

    @Test func faceDownRenders() {
        let host = UIHostingController(rootView: CardView(faceDown: true).frame(width: 88, height: 123))
        host.view.layoutIfNeeded()
        #expect(host.view.bounds.width > 0)
    }

    @Test func assetNameMapping() {
        #expect(CardView(card: Card(rank: .ace, suit: .spades)).assetName == "ace_of_spades")
        #expect(CardView(card: Card(rank: .ten, suit: .hearts)).assetName == "10_of_hearts")
        #expect(CardView(card: Card(rank: .king, suit: .clubs)).assetName == "king_of_clubs")
        #expect(CardView(faceDown: true).assetName == "card_back")
    }
}
