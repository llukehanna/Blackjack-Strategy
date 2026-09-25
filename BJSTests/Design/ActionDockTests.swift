import Testing
import BJSCore
@testable import BJS

@MainActor
struct ActionDockTests {

    @Test("Row 1 is STAND, HIT; row 2 is SPLIT, DOUBLE, SURRENDER; every action appears once")
    func rows() {
        #expect(ActionDockLayout.topRow == [.stand, .hit])
        #expect(ActionDockLayout.bottomRow == [.split, .double, .surrender])
        #expect(Set(ActionDockLayout.topRow + ActionDockLayout.bottomRow) == Set(Action.allCases))
    }

    @Test("Illegal actions are dimmed, the hinted legal action is hinted, others enabled")
    func states() {
        let legal: Set<Action> = [.hit, .stand, .double]
        #expect(ActionDockLayout.state(for: .hit, legal: legal, hint: nil) == .enabled)
        #expect(ActionDockLayout.state(for: .split, legal: legal, hint: nil) == .dimmed)
        #expect(ActionDockLayout.state(for: .double, legal: legal, hint: .double) == .hint)
        #expect(ActionDockLayout.state(for: .stand, legal: legal, hint: .double) == .enabled)
    }

    @Test("A hint on an illegal action never un-dims it")
    func illegalHintStaysDimmed() {
        #expect(ActionDockLayout.state(for: .surrender, legal: [.hit, .stand], hint: .surrender) == .dimmed)
    }

    @Test("Button titles are uppercase action names")
    func titles() {
        #expect(Action.allCases.map(ActionDockLayout.title(for:))
                == ["HIT", "STAND", "DOUBLE", "SPLIT", "SURRENDER"])
    }

    @Test("Minimum tap target is 44 pt")
    func tapTarget() {
        #expect(FeltTapTarget.minimum == 44)
        #expect(ActionDockLayout.bottomRowHeight >= FeltTapTarget.minimum)
        #expect(ActionDockLayout.topRowHeight >= FeltTapTarget.minimum)
    }

    @Test("Feedback badge: ✓ on correct, ✕ on incorrect")
    func verdicts() {
        #expect(FeedbackVerdict.correct.glyph == "checkmark")
        #expect(FeedbackVerdict.incorrect.glyph == "xmark")
        #expect(FeedbackVerdict.correct.accessibilityLabel == "Correct")
        #expect(FeedbackVerdict.incorrect.accessibilityLabel == "Incorrect")
    }
}
