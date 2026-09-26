import Foundation
import Testing
@testable import BJS

@MainActor
struct StrategyComponentTests {

    let t0 = Date(timeIntervalSince1970: 0)

    @Test("Countdown fraction drains linearly and clamps")
    func countdown() {
        #expect(CountdownProgress.remainingFraction(startedAt: t0, now: t0, duration: 3) == 1)
        #expect(CountdownProgress.remainingFraction(startedAt: t0, now: t0.addingTimeInterval(1.5), duration: 3) == 0.5)
        #expect(CountdownProgress.remainingFraction(startedAt: t0, now: t0.addingTimeInterval(9), duration: 3) == 0)
        #expect(CountdownProgress.remainingFraction(startedAt: t0, now: t0.addingTimeInterval(-1), duration: 3) == 1)
    }

    @Test("The last second is urgent")
    func urgent() {
        #expect(!CountdownProgress.isUrgent(startedAt: t0, now: t0.addingTimeInterval(1.9), duration: 3))
        #expect(CountdownProgress.isUrgent(startedAt: t0, now: t0.addingTimeInterval(2), duration: 3))
    }

    @Test("One hand uses the max card width; more hands shrink to fit")
    func splitWidths() {
        #expect(SplitHandsLayout.cardWidth(handCount: 1, cardsPerHand: 3, availableWidth: 343) == SplitHandsLayout.maxCardWidth)
        for count in 2...4 {
            let w = SplitHandsLayout.cardWidth(handCount: count, cardsPerHand: 3, availableWidth: 343)
            let handWidth = HandLayout.totalWidth(count: 3, cardWidth: w, overlap: SplitHandsLayout.overlap)
            let total = CGFloat(count) * handWidth + CGFloat(count - 1) * FeltSpacing.m
            #expect(total <= 343.5, "\(count) hands overflow: \(total)")
            #expect(w >= SplitHandsLayout.minCardWidth)
        }
    }

    @Test("Toast display duration")
    func toast() {
        #expect(FeltToast.displayDuration == 0.8)
    }
}
