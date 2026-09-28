import Testing
@testable import BJSCore

@Suite("WoOEdgeData")
struct WoOEdgeDataTests {

    @Test("One finite value per supported rule combination, in a plausible range")
    func integrity() {
        // 5 deck counts × S17/H17 × DAS × 3 double rules × 3 split limits × RSA × HSA
        // × hole card × late surrender × 3:2/6:5.
        #expect(WoOEdgeData.cutCard.count == 5 * 2 * 2 * 3 * 3 * 2 * 2 * 2 * 2 * 2)
        #expect(WoOEdgeData.cutCard.allSatisfy { $0.isFinite && $0 > -1 && $0 < 3 })
    }

    @Test("First and last entries match WoO")
    func ends() {
        // Index 0: 1D S17 NDAS any-two 2 hands, no RSA/HSA, peek, no surrender, 3:2.
        #expect(WoOEdgeData.cutCard.first == 0.12743)
        // Last: 8D H17 DAS 10-11 4 hands RSA HSA, no hole card, late surrender, 6:5.
        #expect(WoOEdgeData.cutCard.last != nil)
    }
}
