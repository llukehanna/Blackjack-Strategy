import BJSCore
import Testing
@testable import BJS

@MainActor
@Suite("ActionDock")
struct ActionDockTests {

    @Test("Rows are STAND, HIT then SPLIT, DOUBLE, SURRENDER")
    func layout() {
        #expect(ActionDock.primaryRow == [.stand, .hit])
        #expect(ActionDock.secondaryRow == [.split, .double, .surrender])
        #expect(Set(ActionDock.primaryRow + ActionDock.secondaryRow) == Set(Action.allCases))
    }

    @Test("Actions the rules do not allow are dimmed")
    func dimmed() {
        let allowed: Set<Action> = [.hit, .stand]
        #expect(ActionDock.state(for: .double, allowed: allowed, hint: nil) == .dimmed)
        #expect(ActionDock.state(for: .split, allowed: allowed, hint: nil) == .dimmed)
        #expect(ActionDock.state(for: .hit, allowed: allowed, hint: nil) == .enabled)
    }

    @Test("The hinted action gets the hint state; others stay enabled")
    func hint() {
        let allowed = Set(Action.allCases)
        #expect(ActionDock.state(for: .double, allowed: allowed, hint: .double) == .hint)
        #expect(ActionDock.state(for: .hit, allowed: allowed, hint: .double) == .enabled)
    }

    @Test("A hint on a disallowed action is still dimmed")
    func hintNeverOverridesRules() {
        #expect(ActionDock.state(for: .surrender, allowed: [.hit, .stand], hint: .surrender) == .dimmed)
    }

    @Test("Captions are uppercase; VoiceOver names are capitalised")
    func titles() {
        #expect(ActionDock.title(for: .surrender) == "SURRENDER")
        #expect(ActionDock.spokenName(for: .double) == "Double")
    }
}
