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
                let view = CardView(card: card, width: 88)
                let host = UIHostingController(rootView: view)
                host.view.frame = CGRect(x: 0, y: 0, width: 88, height: 123)
                host.view.layoutIfNeeded()
                #expect(host.view.bounds.width > 0)
            }
        }
    }

    @Test func faceDownRenders() {
        let host = UIHostingController(rootView: CardView(faceDown: true, width: 88))
        host.view.frame = CGRect(x: 0, y: 0, width: 88, height: 123)
        host.view.layoutIfNeeded()
        #expect(host.view.bounds.width > 0)
    }

    @Test func assetNameMapping() {
        #expect(CardView(card: Card(rank: .ace, suit: .spades), width: 88).assetName == "ace_of_spades")
        #expect(CardView(card: Card(rank: .ten, suit: .hearts), width: 88).assetName == "10_of_hearts")
        #expect(CardView(card: Card(rank: .king, suit: .clubs), width: 88).assetName == "king_of_clubs")
        #expect(CardView(faceDown: true, width: 88).assetName == "card_back")
    }
}
