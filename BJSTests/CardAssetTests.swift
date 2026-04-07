import Testing
import UIKit
@testable import BJS
import BJSCore

struct CardAssetTests {
    @Test func allFaceCardsResolve() {
        let bundle = Bundle(for: BJSTestMarker.self)
        for rank in Rank.allCases {
            for suit in Suit.allCases {
                let name = "\(CardView.rankName(rank))_of_\(CardView.suitName(suit))"
                // Try app bundle first, then test bundle as fallback.
                let image = UIImage(named: name) ?? UIImage(named: name, in: bundle, compatibleWith: nil)
                #expect(image != nil, "Missing card asset: \(name)")
            }
        }
    }

    @Test func cardBackResolves() {
        let bundle = Bundle(for: BJSTestMarker.self)
        let image = UIImage(named: "card_back") ?? UIImage(named: "card_back", in: bundle, compatibleWith: nil)
        #expect(image != nil, "Missing card_back asset")
    }
}

/// Marker class used only to resolve the current test bundle.
private final class BJSTestMarker {}
