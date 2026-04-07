import Testing
import SwiftUI
@testable import BJS
import BJSCore

@MainActor
struct HandViewTests {
    @Test func overlapValues() {
        #expect(HandOverlap.dealer.rawValue == 0.30)
        #expect(HandOverlap.player.rawValue == 0.45)
    }

    @Test func handViewHostsWithoutCrash() {
        let cards = [
            Card(rank: .ace, suit: .spades),
            Card(rank: .king, suit: .hearts)
        ]
        let view = HandView(cards: cards, overlap: .player)
        let host = UIHostingController(rootView: view)
        host.view.layoutIfNeeded()
        #expect(host.view.bounds.width >= 0)
    }
}
