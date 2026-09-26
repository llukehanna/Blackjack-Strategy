# Step 3 — Strategy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Strategy module: setup, trainer in four modes (Learn / Test / Speed / Weak spots), WHY sheet, summary, persistence and the hub's Continue button.

**Architecture:**
- **BJSCore:**
  - WoO's early-surrender composition note for hard 14 vs 10, applied in `StrategyTable` grading;
  - a spot-aware `WhyContext` initialiser;
  - richer WHY templates.
- **App:**
  - `StrategyTrainerViewModel` is a thin `@Observable` phase machine over `RoundEngine`, with an injected seed, clock, shoe maker and persist closure;
  - views are built from the frozen Felt kit plus four new components;
  - hub → module routing moves to the App layer through `AppRouter.launch`, so features never reference each other.

**Tech Stack:** Swift 6.2, SwiftUI (iOS 18+), SwiftData, Swift Testing, XCTest UI tests, XcodeGen.

**Spec:** `docs/superpowers/specs/2026-09-25-step-3-strategy-design.md`. The parent spec is `docs/superpowers/specs/2026-09-23-bjs-rebuild-design.md`. Read both before starting a task.

## Global Constraints

- All game logic lives in `BJSCore`, which never imports SwiftUI or SwiftData.
- ViewModels are thin `@Observable` adapters.
- Feature folders (`BJS/Features/*`) never reference each other's types. Shared code goes in `BJS/Design`, `BJS/Shared`, `BJS/Persistence` or `BJSCore`. `BJS/App` is the composition layer and may reference features.
- **Felt is frozen.** Do not change any existing token or component in `BJS/Design`. New components built from existing tokens are allowed. Adding them to `FeltCatalogue` is required.
- Randomness is injectable. Tests use `SeededRandomNumberGenerator(seed:)`.
- The app target builds with `-enable-upcoming-feature DefaultIsolationMainActor`:
  - **Do not form `\.prop` key paths** on app-module types (for example `decisions.map(\.handNumber)`). Use closures (`decisions.map { $0.handNumber }`).
  - Key paths on BJSCore types are fine.
  - If a `Codable` app value type fails to compile because of isolation, mark it `nonisolated`.
- Tests:
  - Swift Testing (`@Test`, `#expect`, `#require`) for unit tests; app test structs are `@MainActor`.
  - XCTest only for UI tests.
- XcodeGen owns the project. After adding files, run `xcodegen generate`. Never edit `.xcodeproj`.
- Commit after each task. Use conventional prefixes with a scope (`feat(core)`, `feat(strategy)`, `test(app)`, …). End every commit message with:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
- Commands:
  - Engine: `cd BJSCore && swift test`
  - App: `xcodegen generate && xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -quiet`
  - A single app suite: add `-only-testing:BJSTests/<SuiteName>`.
- Test baselines before this step: BJSCore 211 tests, app 80 unit tests + 1 UI test. They must stay green.

---

## File map

**BJSCore**
- Modify `BJSCore/Sources/BJSCore/Strategy/StrategyTable.swift`: `hard14VsTenSurrenders`, `preferences(for:dealerUpcard:legal:)`, `compositionNoteApplies(to:dealerUpcard:)`.
- Modify `BJSCore/Sources/BJSCore/Strategy/WoOChartDecoder.swift`: builds the composition set.
- Modify `BJSCore/Sources/BJSCore/Explain/WhyExplanation.swift`: `WhyContext` fields, `SurrenderContext`, spot initialiser, templates.
- Create `BJSCore/Tests/BJSCoreTests/StrategyTests/EarlySurrenderCompositionTests.swift`.
- Create `BJSCore/Tests/BJSCoreTests/ExplainTests/WhyContextSpotTests.swift`.

**App**
- Create `BJS/Shared/AppModule.swift`, which replaces `BJS/Features/Hub/HubModule.swift` (deleted).
- Modify:
  - `BJS/Shared/AppRouter.swift`: `launch`.
  - `BJS/Shared/PreferencesStore.swift`: decode log.
  - `BJS/Persistence/SessionStore.swift`: `forStats`.
  - `BJS/Features/Hub/HubView.swift` and `HubViewModel.swift`: tiles and Continue set `router.launch`.
  - `BJS/App/RootTabView.swift`: the launch cover.
  - `BJS/App/LaunchConfiguration.swift`: `-strategyLength` and `-seed`.
- Create `BJS/App/ModuleHost.swift`.
- Create in `BJS/Features/Strategy/`:
  - `StrategySetup.swift`
  - `StrategyText.swift`
  - `StrategyTrainerViewModel.swift`
  - `StrategyFlowView.swift`
  - `StrategySetupView.swift`
  - `StrategyTrainerView.swift`
  - `DealerHandView.swift`
  - `WhySheet.swift`
  - `StrategySummaryView.swift`
- Create in `BJS/Design/Components/`:
  - `FlipCard.swift`
  - `FeltToast.swift`
  - `CountdownBar.swift`
  - `SplitHandsView.swift`
- Modify `BJS/Design/Catalogue/FeltCatalogue.swift`: add a "Strategy components" section.
- Tests:
  - `BJSTests/Features/StrategySetupTests.swift`
  - `BJSTests/Features/StrategyTextTests.swift`
  - `BJSTests/Features/StrategyTrainerViewModelTests.swift`
  - `BJSTests/Features/StrategySessionTests.swift`
  - `BJSTests/Features/HubLaunchTests.swift`
  - `BJSTests/Design/StrategyComponentTests.swift`
  - additions to `BJSTests/Persistence/SessionStoreTests.swift` and `BJSTests/AppShellTests.swift`
  - `BJSUITests/StrategyUITests.swift`
- Docs: `docs/superpowers/progress.md` (handoff).

---

### Task 1: Early-surrender composition note in grading (BJSCore)

**Files:**
- Modify: `BJSCore/Sources/BJSCore/Strategy/StrategyTable.swift`
- Modify: `BJSCore/Sources/BJSCore/Strategy/WoOChartDecoder.swift`
- Test: `BJSCore/Tests/BJSCoreTests/StrategyTests/EarlySurrenderCompositionTests.swift`

**Interfaces:**
- Produces:
  - `StrategyTable.hard14VsTenSurrenders: Set<[Int]>?`;
  - `StrategyTable.preferences(for: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> [Action]` (the graded row);
  - `StrategyTable.compositionNoteApplies(to: BlackjackHand, dealerUpcard: Rank) -> Bool`.
  - `action(for:dealerUpcard:legal:)` and `action(for: DecisionSpot)` apply the note.

Source, verified on 2026-09-25 at https://wizardofodds.com/games/blackjack/surrender/, early-surrender list:

> Dealer 10 Vs. hard 14-16 … Do not surrender 10 Vs. 4+10 or 5+9 in single deck. Do not surrender 10 Vs. 4+10 in double deck.

So under early surrender with American peek:
- 1 deck: surrender 8+6; hit 10+4 and 9+5.
- 2 decks: surrender 9+5 and 8+6; hit 10+4.
- 4+ decks: the chart already surrenders every hard 14 vs 10 (unchanged).

The decoder currently reduces this to "no surrender of hard 14 vs 10 with 1 or 2 decks" (`earlySurrenderListed`). That stays as the chart cell, and the composition set overrides it for the listed two-card hands.

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
@testable import BJSCore

struct EarlySurrenderCompositionTests {

    func rules(_ decks: BlackjackRules.DeckCount, surrender: BlackjackRules.SurrenderRule = .early,
               peek: BlackjackRules.PeekRule = .americanPeek) -> BlackjackRules {
        var r = BlackjackRules()
        r.deckCount = decks
        r.surrenderRule = surrender
        r.peekRule = peek
        return r
    }

    func hand(_ a: Rank, _ b: Rank) -> BlackjackHand {
        BlackjackHand(cards: [Card(rank: a, suit: .spades), Card(rank: b, suit: .hearts)])
    }

    let firstDecision: Set<Action> = [.hit, .stand, .double, .surrender]

    @Test("Single deck: surrender 8+6 vs 10, hit 10+4 and 9+5",
          arguments: [(Rank.eight, Rank.six, Action.surrender), (.six, .eight, .surrender),
                      (.ten, .four, .hit), (.king, .four, .hit), (.nine, .five, .hit)])
    func singleDeck(a: Rank, b: Rank, expected: Action) {
        let table = WoOChartDecoder.table(for: rules(.one))
        #expect(table.action(for: hand(a, b), dealerUpcard: .king, legal: firstDecision) == expected)
        #expect(table.action(for: hand(a, b), dealerUpcard: .ten, legal: firstDecision) == expected)
    }

    @Test("Double deck: surrender 9+5 and 8+6 vs 10, hit 10+4",
          arguments: [(Rank.eight, Rank.six, Action.surrender), (.nine, .five, .surrender),
                      (.ten, .four, .hit), (.queen, .four, .hit)])
    func doubleDeck(a: Rank, b: Rank, expected: Action) {
        let table = WoOChartDecoder.table(for: rules(.two))
        #expect(table.action(for: hand(a, b), dealerUpcard: .jack, legal: firstDecision) == expected)
    }

    @Test("Six decks: every hard 14 surrenders vs 10 (chart unchanged)",
          arguments: [(Rank.ten, Rank.four), (.nine, .five), (.eight, .six)])
    func sixDeck(a: Rank, b: Rank) {
        let table = WoOChartDecoder.table(for: rules(.six))
        #expect(table.hard14VsTenSurrenders == nil)
        #expect(table.action(for: hand(a, b), dealerUpcard: .ten, legal: firstDecision) == .surrender)
    }

    @Test("The note needs early surrender under American peek")
    func onlyEarlyPeek() {
        #expect(WoOChartDecoder.table(for: rules(.one, surrender: .late)).hard14VsTenSurrenders == nil)
        #expect(WoOChartDecoder.table(for: rules(.one, surrender: .none)).hard14VsTenSurrenders == nil)
        #expect(WoOChartDecoder.table(for: rules(.one, peek: .europeanNoPeek)).hard14VsTenSurrenders == nil)
        #expect(WoOChartDecoder.table(for: rules(.one)).hard14VsTenSurrenders == [[6, 8]])
        #expect(WoOChartDecoder.table(for: rules(.two)).hard14VsTenSurrenders == [[5, 9], [6, 8]])
    }

    @Test("Other upcards, three-card 14s and surrender-illegal spots are unaffected")
    func unaffected() {
        let table = WoOChartDecoder.table(for: rules(.one))
        let chartVsAce = table.hardCells[9][9].first(where: firstDecision.contains)
        #expect(table.action(for: hand(.eight, .six), dealerUpcard: .ace, legal: firstDecision) == chartVsAce)
        let threeCard = BlackjackHand(cards: [Card(rank: .four, suit: .spades), Card(rank: .five, suit: .hearts),
                                              Card(rank: .five, suit: .clubs)])
        #expect(table.action(for: threeCard, dealerUpcard: .ten, legal: [.hit, .stand]) == .hit)
        #expect(table.action(for: hand(.eight, .six), dealerUpcard: .ten, legal: [.hit, .stand]) == .hit)
    }

    @Test("7,7 vs 10 is graded on its pair row (surrender)")
    func sevensUsePairRow() {
        let table = WoOChartDecoder.table(for: rules(.one))
        #expect(table.action(for: hand(.seven, .seven), dealerUpcard: .ten,
                             legal: firstDecision.union([.split])) == .surrender)
    }

    @Test("compositionNoteApplies only to two-card non-pair hard 14 vs ten-value under the note")
    func noteApplies() {
        let one = WoOChartDecoder.table(for: rules(.one))
        #expect(one.compositionNoteApplies(to: hand(.ten, .four), dealerUpcard: .king))
        #expect(one.compositionNoteApplies(to: hand(.eight, .six), dealerUpcard: .ten))
        #expect(!one.compositionNoteApplies(to: hand(.eight, .six), dealerUpcard: .ace))
        #expect(!one.compositionNoteApplies(to: hand(.seven, .seven), dealerUpcard: .ten))
        #expect(!one.compositionNoteApplies(to: hand(.ten, .five), dealerUpcard: .ten))
        #expect(!WoOChartDecoder.table(for: rules(.six)).compositionNoteApplies(to: hand(.ten, .four), dealerUpcard: .ten))
    }

    @Test("preferences returns the graded row: pair row only while split is legal")
    func preferencesRow() {
        let table = WoOChartDecoder.table(for: BlackjackRules())
        let eights = hand(.eight, .eight)
        #expect(table.preferences(for: eights, dealerUpcard: .six, legal: [.hit, .stand, .split]).first == .split)
        #expect(table.preferences(for: eights, dealerUpcard: .six, legal: [.hit, .stand])
                == table.hardCells[11][4])
        let aces = hand(.ace, .ace)
        #expect(table.preferences(for: aces, dealerUpcard: .six, legal: [.hit, .stand]) == [.hit, .stand])
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd BJSCore && swift test --filter EarlySurrenderCompositionTests`
Expected: compile failure (`hard14VsTenSurrenders`, `preferences`, `compositionNoteApplies` don't exist).

- [ ] **Step 3: Implement in `StrategyTable`**

Add the stored property and the init parameter. The default is `nil`, so other call sites keep compiling:

```swift
    /// WoO's early-surrender composition note (1-2 decks, American peek): the two-card hard 14
    /// compositions, as sorted card values (e.g. [6, 8]), that surrender against a ten-value upcard.
    /// Other hard 14s follow the chart cell. nil when the note doesn't apply to the rules.
    public let hard14VsTenSurrenders: Set<[Int]>?

    init(hardCells: [[[Action]]], softCells: [[[Action]]], pairCells: [[[Action]]],
         hard14VsTenSurrenders: Set<[Int]>? = nil) {
        self.hardCells = hardCells
        self.softCells = softCells
        self.pairCells = pairCells
        self.hard14VsTenSurrenders = hard14VsTenSurrenders
    }
```

Replace `action(for:dealerUpcard:legal:)` with `preferences` + `action`. Keep the existing doc comment on `action`, adding one line about the composition note:

```swift
    /// The preference list grading reads for this hand: the pair row while split is legal and
    /// the row has a legal action, `[hit, stand]` for an unsplittable soft 12, otherwise the
    /// hand's hard or soft row.
    public func preferences(for hand: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> [Action] {
        let col = dealerUpcard.columnIndex
        if hand.isPair, legal.contains(.split) {
            let row = pairCells[hand.pairIndex][col]
            if row.contains(where: legal.contains) { return row }
        }
        if hand.isSoft && hand.total == 12 { return [.hit, .stand] }
        return hand.isSoft ? softCells[hand.softIndex][col] : hardCells[hand.hardIndex][col]
    }

    public func action(for hand: BlackjackHand, dealerUpcard: Rank, legal: Set<Action>) -> Action {
        if legal.contains(.surrender), let allowed = hard14VsTenSurrenders,
           compositionNoteApplies(to: hand, dealerUpcard: dealerUpcard),
           allowed.contains(hand.cards.map { $0.rank.blackjackValue }.sorted()) {
            return .surrender
        }
        return preferences(for: hand, dealerUpcard: dealerUpcard, legal: legal).first(where: legal.contains) ?? .stand
    }

    /// True for a two-card, non-pair hard 14 against a ten-value upcard when the rules carry
    /// WoO's early-surrender composition note.
    public func compositionNoteApplies(to hand: BlackjackHand, dealerUpcard: Rank) -> Bool {
        hard14VsTenSurrenders != nil && hand.cards.count == 2 && !hand.isPair && !hand.isSoft
            && hand.total == 14 && dealerUpcard.blackjackValue == 10
    }
```

In `WoOChartDecoder.table(for:)`, pass the set:

```swift
        return StrategyTable(hardCells: grid(hardRows), softCells: grid(softRows),
                             pairCells: grid(pairRows),
                             hard14VsTenSurrenders: earlySurrender14Compositions(rules))
```

Add this to `WoOChartDecoder`, and update the `earlySurrenderListed` doc comment to point at it:

```swift
    /// WoO's composition note for early surrender of hard 14 vs 10 ("Do not surrender 10 Vs. 4+10
    /// or 5+9 in single deck"; "Do not surrender 10 Vs. 4+10 in double deck"), as the sorted
    /// two-card values that do surrender. With 4+ decks every hard 14 surrenders, so no note.
    static func earlySurrender14Compositions(_ rules: BlackjackRules) -> Set<[Int]>? {
        guard rules.surrenderRule == .early, rules.peekRule == .americanPeek else { return nil }
        switch rules.deckCount {
        case .one: return [[6, 8]]
        case .two: return [[5, 9], [6, 8]]
        case .four, .six, .eight: return nil
        }
    }
```

- [ ] **Step 4: Run all engine tests**

Run: `cd BJSCore && swift test`
Expected: all pass (211 + the new ones). `WoOChartTests` are unchanged, because the grids still show the total-level cell.

- [ ] **Step 5: Commit**

```bash
git add BJSCore
git commit -m "feat(core): apply WoO's early-surrender composition note for hard 14 vs 10"
```

---

### Task 2: Spot-aware `WhyContext` and richer WHY templates (BJSCore)

**Files:**
- Modify: `BJSCore/Sources/BJSCore/Explain/WhyExplanation.swift`
- Test: `BJSCore/Tests/BJSCoreTests/ExplainTests/WhyContextSpotTests.swift`. The existing `WhyExplanationTests.swift` must still pass unchanged.

**Interfaces:**
- Consumes: `StrategyTable.preferences(for:dealerUpcard:legal:)`, `compositionNoteApplies(to:dealerUpcard:)`, `action(for: DecisionSpot)` (Task 1).
- Produces:
  - `WhyContext.userAction: Action?` (`nil` = Speed timeout);
  - new stored fields `preferredIllegal: Action?`, `surrenderContext: SurrenderContext?`, `compositionNote: Bool`, which default to `nil`/`nil`/`false` in the memberwise init;
  - `public enum SurrenderContext { case late, early, noHoleCard }` with `init?(rules:)`;
  - `WhyContext.init(spot: DecisionSpot, userAction: Action?, table: StrategyTable, rules: BlackjackRules)`.

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
@testable import BJSCore

struct WhyContextSpotTests {

    func card(_ r: Rank, _ s: Suit = .spades) -> Card { Card(rank: r, suit: s) }
    func spot(_ ranks: [Rank], up: Rank, legal: Set<Action>) -> DecisionSpot {
        DecisionSpot(hand: BlackjackHand(cards: ranks.enumerated().map { card($1, Suit.allCases[$0 % 4]) }),
                     dealerUpcard: up, legalActions: legal)
    }
    func context(_ s: DecisionSpot, rules: BlackjackRules = BlackjackRules(), user: Action? = .stand) -> WhyContext {
        WhyContext(spot: s, userAction: user, table: StrategyEngine().strategy(for: rules), rules: rules)
    }

    @Test("A pair is a pair only while split is legal")
    func pairRow() {
        let splittable = context(spot([.eight, .eight], up: .six, legal: [.hit, .stand, .double, .split]))
        #expect(splittable.handType == .pair)
        #expect(splittable.pairRank == .eight)
        #expect(splittable.correctAction == .split)
        let unsplittable = context(spot([.eight, .eight], up: .six, legal: [.hit, .stand, .double]))
        #expect(unsplittable.handType == .hard)
        #expect(unsplittable.handTotal == 16)
        #expect(unsplittable.pairRank == nil)
    }

    @Test("A three-card soft 18 vs 6 records double as the preferred-but-illegal play")
    func preferredIllegalDouble() {
        let c = context(spot([.ace, .four, .three], up: .six, legal: [.hit, .stand]))
        #expect(c.handType == .soft)
        #expect(c.correctAction == .stand)
        #expect(c.preferredIllegal == .double)
        #expect(WhyExplanation.explain(c).hasPrefix("Doubling would be best"))
    }

    @Test("No preferredIllegal when the first preference is legal")
    func noPreferredIllegal() {
        #expect(context(spot([.ten, .six], up: .ten, legal: [.hit, .stand, .double])).preferredIllegal == nil)
    }

    @Test("SurrenderContext follows surrender and peek rules")
    func surrenderContext() {
        var r = BlackjackRules()
        #expect(SurrenderContext(rules: r) == nil)
        r.surrenderRule = .late
        #expect(SurrenderContext(rules: r) == .late)
        r.surrenderRule = .early
        #expect(SurrenderContext(rules: r) == .early)
        r.peekRule = .europeanNoPeek
        #expect(SurrenderContext(rules: r) == .noHoleCard)
        r.surrenderRule = .late
        #expect(SurrenderContext(rules: r) == .noHoleCard)
    }

    @Test("Early surrender of hard 5 vs A explains surrendering before the peek")
    func earlySurrenderReason() {
        var r = BlackjackRules()
        r.surrenderRule = .early
        let c = context(spot([.two, .three], up: .ace, legal: [.hit, .stand, .double, .surrender]), rules: r)
        #expect(c.correctAction == .surrender)
        #expect(WhyExplanation.explain(c).contains("before the dealer checks for blackjack"))
    }

    @Test("No-hole-card surrender explains the later dealer blackjack")
    func noHoleCardReason() {
        var r = BlackjackRules()
        r.surrenderRule = .late
        r.peekRule = .europeanNoPeek
        let c = context(spot([.ten, .six], up: .ten, legal: [.hit, .stand, .double, .surrender]), rules: r)
        #expect(c.correctAction == .surrender)
        #expect(WhyExplanation.explain(c).contains("no hole card"))
    }

    @Test("The hard 14 vs 10 composition note names the deck-specific cards")
    func compositionNote() {
        var r = BlackjackRules()
        r.deckCount = .one
        r.surrenderRule = .early
        let c = context(spot([.ten, .four], up: .ten, legal: [.hit, .stand, .double, .surrender]), rules: r)
        #expect(c.compositionNote)
        #expect(c.correctAction == .hit)
        #expect(WhyExplanation.explain(c).contains("surrender 8+6"))
    }

    @Test("A timeout context has no user action")
    func timeout() {
        #expect(context(spot([.ten, .six], up: .ten, legal: [.hit, .stand]), user: nil).userAction == nil)
    }

    @Test("Every two-card spot under several rule sets explains within 30..<400 characters, ending in a full stop")
    func bounds() {
        var ruleSets: [BlackjackRules] = [BlackjackRules()]
        for (decks, surrender, peek) in [(BlackjackRules.DeckCount.one, BlackjackRules.SurrenderRule.early, BlackjackRules.PeekRule.americanPeek),
                                         (.two, .early, .americanPeek), (.six, .late, .europeanNoPeek),
                                         (.eight, .late, .americanPeek)] {
            var r = BlackjackRules()
            r.deckCount = decks
            r.surrenderRule = surrender
            r.peekRule = peek
            r.doubleRestriction = .tenToEleven
            ruleSets.append(r)
        }
        for rules in ruleSets {
            let table = StrategyEngine().strategy(for: rules)
            for first in Rank.allCases { for second in Rank.allCases { for up in Rank.allCases {
                let hand = BlackjackHand(cards: [card(first, .spades), card(second, .hearts)])
                guard !hand.isBlackjack else { continue }
                var legal: Set<Action> = [.hit, .stand]
                if hand.canDouble(rules: rules) { legal.insert(.double) }
                if hand.isPair { legal.insert(.split) }
                if rules.surrenderRule != .none { legal.insert(.surrender) }
                let c = WhyContext(spot: DecisionSpot(hand: hand, dealerUpcard: up, legalActions: legal),
                                   userAction: .hit, table: table, rules: rules)
                let text = WhyExplanation.explain(c)
                #expect((30..<400).contains(text.count), "\(text.count): \(text)")
                #expect(text.hasSuffix(".") || text.hasSuffix("!"), "\(text)")
            } } }
        }
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd BJSCore && swift test --filter WhyContextSpotTests`
Expected: compile failure.

- [ ] **Step 3: Implement**

In `WhyExplanation.swift`:

1. Add the surrender context:

```swift
/// How surrender works under the rules, for explaining surrender plays.
public enum SurrenderContext: String, Sendable, Equatable {
    case late, early, noHoleCard

    /// nil when surrender isn't offered. Under no hole card, late and early play the same.
    public init?(rules: BlackjackRules) {
        switch rules.surrenderRule {
        case .none: return nil
        case .late: self = rules.peekRule == .europeanNoPeek ? .noHoleCard : .late
        case .early: self = rules.peekRule == .europeanNoPeek ? .noHoleCard : .early
        }
    }
}
```

2. In `WhyContext`:
   - change `public let userAction: Action` to `public let userAction: Action?` and document that `nil` means a Speed-mode timeout;
   - add `public let preferredIllegal: Action?`, `public let surrenderContext: SurrenderContext?` and `public let compositionNote: Bool`;
   - extend the memberwise `init` with `preferredIllegal: Action? = nil, surrenderContext: SurrenderContext? = nil, compositionNote: Bool = false` after `rules`, and change its `userAction` parameter type to `Action?`.

3. Add the spot initialiser:

```swift
extension WhyContext {
    /// Builds the context from the row grading used: a pair only while split is legal,
    /// otherwise the hand's soft or hard total.
    public init(spot: DecisionSpot, userAction: Action?, table: StrategyTable, rules: BlackjackRules,
                id: UUID = UUID()) {
        let hand = spot.hand
        let legal = spot.legalActions
        let type: HandType = hand.isPair && legal.contains(.split) ? .pair : (hand.isSoft ? .soft : .hard)
        let correct = table.action(for: spot)
        let first = table.preferences(for: hand, dealerUpcard: spot.dealerUpcard, legal: legal).first
        let illegal = first.flatMap { legal.contains($0) || $0 == correct ? nil : $0 }
        self.init(id: id, handTotal: hand.total, handType: type,
                  pairRank: type == .pair ? hand.cards[0].rank : nil,
                  dealerUpCard: spot.dealerUpcard, userAction: userAction, correctAction: correct,
                  rules: rules, preferredIllegal: illegal, surrenderContext: SurrenderContext(rules: rules),
                  compositionNote: table.compositionNoteApplies(to: hand, dealerUpcard: spot.dealerUpcard))
    }
}
```

4. In `explain`, compose the lead, the template and the note:

```swift
    public static func explain(_ context: WhyContext) -> String {
        let raw = [illegalLead(context), template(for: context), compositionText(context)]
            .compactMap { $0 }
            .joined(separator: " ")
        // ...existing trimming / padding / 399 cap unchanged, applied to `raw`
    }

    private static func illegalLead(_ c: WhyContext) -> String? {
        guard let action = c.preferredIllegal else { return nil }
        return "\(gerund(action)) would be best, but it isn't allowed on this hand."
    }

    private static func gerund(_ action: Action) -> String {
        switch action {
        case .hit: return "Hitting"
        case .stand: return "Standing"
        case .double: return "Doubling"
        case .split: return "Splitting"
        case .surrender: return "Surrendering"
        }
    }

    private static func compositionText(_ c: WhyContext) -> String? {
        guard c.compositionNote else { return nil }
        switch c.rules.deckCount {
        case .one:
            return "With one deck, early surrender of hard 14 vs 10 depends on the cards: surrender 8+6, but hit 10+4 and 9+5."
        default:
            return "With two decks, early surrender of hard 14 vs 10 depends on the cards: surrender 9+5 and 8+6, but hit 10+4."
        }
    }

    /// Why surrendering beats playing on when the dealer's blackjack is still unknown.
    private static func surrenderReason(_ c: WhyContext) -> String? {
        let tenOrAce = c.dealerUpCard == .ace || c.dealerUpCard.blackjackValue == 10
        guard tenOrAce, let context = c.surrenderContext else { return nil }
        switch context {
        case .late: return nil
        case .early:
            return "early surrender lets you give up half your bet before the dealer checks for blackjack, which saves you from the naturals that would take your whole bet."
        case .noHoleCard:
            return "with no hole card the dealer can still turn over a blackjack after you act, but a surrendered hand keeps half its bet, so giving up now beats playing into that risk."
        }
    }
```

5. In `template(for:)`, start the `(.hard, .surrender)` and `(.pair, .surrender)` cases with:

```swift
        case (.hard, .surrender):
            if let reason = surrenderReason(c) { return "Hard \(total) vs dealer's \(up): \(reason)" }
            return /* existing hard-surrender text */

        case (.pair, .surrender):
            if let reason = surrenderReason(c) {
                return "Pair of \(pairRankName(c.pairRank))s vs dealer's \(up): \(reason)"
            }
            return /* existing pair-surrender text */
```

6. Fix any existing test helper that stops compiling because of `userAction: Action?`. Passing an `Action` still compiles through implicit optional promotion. Do not change the existing assertions.

- [ ] **Step 4: Run all engine tests**

Run: `cd BJSCore && swift test`
Expected: all pass. If `bounds` finds a text ≥ 400 or without a full stop, shorten the template involved. Never raise the cap.

- [ ] **Step 5: Commit**

```bash
git add BJSCore
git commit -m "feat(core): spot-aware WhyContext with illegal-preference, surrender and composition notes"
```

---

### Task 3: `SessionStore` stats view excludes Learn sessions

**Files:**
- Modify: `BJS/Persistence/SessionStore.swift`
- Test: `BJSTests/Persistence/SessionStoreTests.swift` (add tests)

**Interfaces:**
- Produces:
  - `SessionStore.statsExcludedModes: Set<String>` (= `["learn"]`);
  - `sessionSamples(forStats: Bool = true)`;
  - `decisionSamples(modules: Set<TrainingModule>? = nil, forStats: Bool = true)`;
  - `countSamples(modules: Set<TrainingModule>? = nil, forStats: Bool = true)`.
  - Existing call sites keep compiling with the default `forStats: true`.

- [ ] **Step 1: Write the failing tests** (add inside `SessionStoreTests`)

```swift
    func draft(mode: String?, decisions: [DecisionDraft]) -> SessionDraft {
        SessionDraft(module: .strategy, mode: mode, startedAt: t(100), endedAt: t(160),
                     rules: RulePreset.downtownVegas.rules, decisions: decisions)
    }

    @Test("Stats queries drop Learn sessions; forStats: false keeps them")
    func learnExcludedFromStats() throws {
        try store.save(draft(mode: "learn", decisions: [decision(true, at: 101)]))
        try store.save(draft(mode: "test", decisions: [decision(false, at: 102)]))

        #expect(try store.sessionSamples().count == 1)
        #expect(try store.sessionSamples(forStats: false).count == 2)
        #expect(try store.decisionSamples().map { $0.isCorrect } == [false])
        #expect(try store.decisionSamples(forStats: false).count == 2)
        #expect(try store.decisionSamples(modules: [.strategy]).count == 1)
    }

    @Test("Sessions with no mode count towards stats")
    func nilModeCounts() throws {
        try store.save(draft(mode: nil, decisions: [decision(true, at: 101)]))
        #expect(try store.decisionSamples().count == 1)
    }
```

- [ ] **Step 2: Run and confirm failure**

Run: `xcodegen generate && xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -quiet -only-testing:BJSTests/SessionStoreTests`
Expected: compile failure (`forStats` doesn't exist).

- [ ] **Step 3: Implement**

```swift
    /// Session modes whose decisions don't feed accuracy, streaks or weak spots (Step 3 spec §1):
    /// Learn mode shows the answer before the user chooses.
    static let statsExcludedModes: Set<String> = ["learn"]

    /// All sessions, oldest first. `forStats` drops sessions in `statsExcludedModes`.
    func sessionSamples(forStats: Bool = true) throws -> [SessionSample] {
        let sessions = try context.fetch(FetchDescriptor<Session>())
            .filter { !forStats || Self.countsForStats($0) }
            .sorted { $0.startedAt < $1.startedAt }
        return mapLogging(sessions, kind: "session") { $0.sample }
    }

    /// Decisions from sessions in `modules` (all when nil), chronological.
    func decisionSamples(modules: Set<TrainingModule>? = nil, forStats: Bool = true) throws -> [DecisionSample] {
        let records = try context.fetch(FetchDescriptor<DecisionRecord>())
            .filter { Self.matches($0.session, modules) && (!forStats || Self.countsForStats($0.session)) }
            .sorted { ($0.decidedAt, $0.sequence) < ($1.decidedAt, $1.sequence) }
        return mapLogging(records, kind: "decision") { $0.sample }
    }

    /// Count checks from sessions in `modules` (all when nil), chronological.
    func countSamples(modules: Set<TrainingModule>? = nil, forStats: Bool = true) throws -> [CountSample] {
        let records = try context.fetch(FetchDescriptor<CountCheckRecord>())
            .filter { Self.matches($0.session, modules) && (!forStats || Self.countsForStats($0.session)) }
            .sorted { ($0.checkedAt, $0.sequence) < ($1.checkedAt, $1.sequence) }
        return mapLogging(records, kind: "count check") { $0.sample }
    }

    private static func countsForStats(_ session: Session?) -> Bool {
        guard let mode = session?.mode else { return true }
        return !statsExcludedModes.contains(mode)
    }
```

- [ ] **Step 4: Run the app unit tests**

Run the full app test command. Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add BJS BJSTests
git commit -m "feat(persistence): stats sample queries exclude Learn sessions"
```

---

### Task 4: App-level module launch routing, Continue and `lastLaunch` decode log

**Files:**
- Create: `BJS/Shared/AppModule.swift`; delete `BJS/Features/Hub/HubModule.swift`
- Modify:
  - `BJS/Shared/AppRouter.swift`
  - `BJS/Features/Hub/HubView.swift`
  - `BJS/Features/Hub/HubViewModel.swift`
  - `BJS/App/RootTabView.swift`
  - `BJS/Shared/PreferencesStore.swift`
- Create: `BJS/App/ModuleHost.swift`
- Test: `BJSTests/Features/HubLaunchTests.swift`. Update any existing test that references `HubModule` (grep `BJSTests` for it).

**Interfaces:**
- Produces:
  - `enum AppModule: String, CaseIterable, Identifiable { case strategy, counting, shoe, edge }` with `title`, `subtitle`, `step`;
  - `struct ModuleLaunch: Identifiable, Equatable { let id: UUID; let module: AppModule; let setup: Data? }` with `init(module:setup:)`;
  - `AppRouter.launch: ModuleLaunch?`;
  - `HubViewModel.continueLaunch(from: LastLaunch?) -> ModuleLaunch?`;
  - `ModuleHost(launch:onClose:)`.
  - Task 9 replaces the strategy branch of `ModuleHost`.

- [ ] **Step 1: Write the failing tests**

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct HubLaunchTests {

    @Test("Continue maps the last launch's training module to its hub module and keeps the setup")
    func continueMapping() {
        let data = Data("{}".utf8)
        let cases: [(TrainingModule, AppModule)] = [(.strategy, .strategy), (.countingRC, .counting),
                                                    (.countingTC, .counting), (.shoe, .shoe)]
        for (training, app) in cases {
            let launch = HubViewModel.continueLaunch(from: LastLaunch(module: training, mode: "test", setup: data))
            #expect(launch?.module == app)
            #expect(launch?.setup == data)
        }
        #expect(HubViewModel.continueLaunch(from: nil) == nil)
    }

    @Test("Each launch gets a fresh identity, so relaunching the same module re-presents")
    func freshIdentity() {
        #expect(ModuleLaunch(module: .strategy, setup: nil) != ModuleLaunch(module: .strategy, setup: nil))
    }

    @Test("AppRouter starts with no launch")
    func routerDefault() {
        #expect(AppRouter().launch == nil)
    }

    @Test("A corrupt lastLaunch is ignored at load")
    func corruptLastLaunch() {
        let d = makeTestDefaults()
        d.set(Data("nope".utf8), forKey: PreferencesStore.Key.lastLaunch)
        #expect(PreferencesStore(defaults: d).lastLaunch == nil)
    }
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `xcodegen generate && xcodebuild test … -only-testing:BJSTests/HubLaunchTests`
Expected: compile failure.

- [ ] **Step 3: Implement**

`BJS/Shared/AppModule.swift`. Move the body of `HubModule` here unchanged, renamed:

```swift
/// The trainable areas the hub launches (parent spec §5). Shared so the App layer can route
/// launches without the hub knowing about any feature.
enum AppModule: String, CaseIterable, Identifiable {
    case strategy, counting, shoe, edge
    // id, title, subtitle, step: copied verbatim from HubModule
}

/// A request to present a module full-screen. `setup` is the module's own encoded setup
/// (Continue); nil opens the module's setup screen. Every launch has a fresh id.
struct ModuleLaunch: Identifiable, Equatable {
    let id = UUID()
    let module: AppModule
    let setup: Data?
}
```

`AppRouter`: add `var launch: ModuleLaunch? = nil`, documented as "The module presented full-screen over the tabs; set by the hub, cleared on close."

`HubViewModel`:

```swift
    /// The launch the hub's Continue button starts: the last module with its saved setup.
    static func continueLaunch(from last: LastLaunch?) -> ModuleLaunch? {
        guard let last else { return nil }
        let module: AppModule
        switch last.module {
        case .strategy: module = .strategy
        case .countingRC, .countingTC: module = .counting
        case .shoe: module = .shoe
        }
        return ModuleLaunch(module: module, setup: last.setup)
    }
```

`HubView`:
- remove `@State private var presented` and the `.fullScreenCover`;
- tiles call `router.launch = ModuleLaunch(module: module, setup: nil)` and get `.accessibilityIdentifier("hub.tile.\(module.rawValue)")` on the `ModuleTile`;
- replace `ForEach(HubModule.allCases)` with `AppModule.allCases`;
- Continue becomes:

```swift
                    if let launch = HubViewModel.continueLaunch(from: preferences.lastLaunch) {
                        PrimaryButton(title: "Continue") { router.launch = launch }
                            .accessibilityIdentifier("hub.continue")
                    }
```

`BJS/App/ModuleHost.swift`:

```swift
import SwiftUI

/// Presents a launched module. The App layer is the only place that knows every feature.
struct ModuleHost: View {
    let launch: ModuleLaunch
    let onClose: () -> Void

    var body: some View {
        // Strategy is wired to its flow in Step 3 Task 9.
        ComingSoonView(title: launch.module.title, message: "Coming in Step \(launch.module.step)",
                       onClose: onClose)
    }
}
```

`RootTabView`: after `.tint(FeltColor.cream)`, add:

```swift
        .fullScreenCover(item: $router.launch) { launch in
            ModuleHost(launch: launch) { router.launch = nil }
        }
```

`PreferencesStore.init`: replace the `lastLaunch` line with:

```swift
        var lastLaunchFailed = false
        if let data = defaults.data(forKey: Key.lastLaunch) {
            do {
                self.lastLaunch = try JSONDecoder().decode(LastLaunch.self, from: data)
            } catch {
                self.lastLaunch = nil
                lastLaunchFailed = true
            }
        } else {
            self.lastLaunch = nil
        }
        if lastLaunchFailed {
            logger.error("lastLaunch failed to decode; Continue is hidden until the next session")
        }
```

Assigning in `init` does not trigger `didSet`, so the stored bad data stays until the next session overwrites it.

- [ ] **Step 4: Run all app tests**

Expected: all pass, including `FoundationUITests`.

- [ ] **Step 5: Commit**

```bash
git add BJS BJSTests
git commit -m "feat(app): route hub launches through AppRouter; wire Continue; log lastLaunch decode failures"
```

---

### Task 5: Strategy setup model, display text and UI-test launch hooks

**Files:**
- Create: `BJS/Features/Strategy/StrategySetup.swift`, `BJS/Features/Strategy/StrategyText.swift`
- Modify: `BJS/App/LaunchConfiguration.swift`
- Test: `BJSTests/Features/StrategySetupTests.swift`, `BJSTests/Features/StrategyTextTests.swift`, plus additions in `BJSTests/AppShellTests.swift` (where `LaunchConfiguration` is tested; grep to confirm)

**Interfaces:**
- Produces:
  - `enum StrategyMode: String, CaseIterable, Codable { case learn, test, speed, weakSpots }` with `title`, `blurb`, `showsHint`, `isTimed`, `usesWeights`;
  - `enum StrategyLength: Hashable, Codable { case hands(Int), endless }` with `static let options`, `title`, `handLimit: Int?`;
  - `struct StrategySetup: Codable, Equatable { var mode = .test; var length = .hands(25); var filter: HandFilter = .all }` with `func lastLaunch() throws -> LastLaunch` and `static func decode(_ data: Data) -> StrategySetup?`;
  - `extension HandFilter { var title: String }`;
  - `enum StrategyText` with:
    - `actionName(_:) -> String`;
    - `handLabel(_ context: WhyContext) -> String`;
    - `feedback(isCorrect:chosen:correct:label:) -> (headline: String, reason: String)`;
    - `signedUnits(_:) -> String`;
    - `outcomeLines(hands:dealer:) -> [String]`;
  - `LaunchConfiguration.strategyLength: Int?` and `.seed: UInt64?` (honoured only with `-uiTesting`).

- [ ] **Step 1: Write the failing tests**

`StrategySetupTests.swift`:

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct StrategySetupTests {

    @Test("Defaults: Test mode, 25 hands, all hands")
    func defaults() {
        let s = StrategySetup()
        #expect(s.mode == .test)
        #expect(s.length == .hands(25))
        #expect(s.filter == .all)
    }

    @Test("Length options and hand limits")
    func lengths() {
        #expect(StrategyLength.options == [.hands(25), .hands(50), .hands(100), .endless])
        #expect(StrategyLength.options.map { $0.title } == ["25", "50", "100", "∞"])
        #expect(StrategyLength.hands(50).handLimit == 50)
        #expect(StrategyLength.endless.handLimit == nil)
    }

    @Test("Mode behaviour flags")
    func modes() {
        #expect(StrategyMode.allCases.map { $0.title } == ["Learn", "Test", "Speed", "Weak spots"])
        #expect(StrategyMode.learn.showsHint && !StrategyMode.test.showsHint)
        #expect(StrategyMode.speed.isTimed && !StrategyMode.weakSpots.isTimed)
        #expect(StrategyMode.weakSpots.usesWeights && !StrategyMode.test.usesWeights)
        #expect(StrategyMode.learn.rawValue == "learn")
    }

    @Test("Learn is the mode SessionStore excludes from stats")
    func learnExcluded() {
        #expect(SessionStore.statsExcludedModes == [StrategyMode.learn.rawValue])
    }

    @Test("lastLaunch round-trips the setup")
    func lastLaunchRoundTrip() throws {
        let setup = StrategySetup(mode: .speed, length: .endless, filter: .pairs)
        let launch = try setup.lastLaunch()
        #expect(launch.module == .strategy)
        #expect(launch.mode == "speed")
        #expect(StrategySetup.decode(launch.setup) == setup)
    }

    @Test("Undecodable setup data returns nil")
    func badData() {
        #expect(StrategySetup.decode(Data("x".utf8)) == nil)
    }

    @Test("Filter titles")
    func filterTitles() {
        #expect(HandFilter.allCases.map { $0.title } == ["All", "Hard", "Soft", "Pairs"])
    }
}
```

`StrategyTextTests.swift`:

```swift
import Testing
import BJSCore
@testable import BJS

@MainActor
struct StrategyTextTests {

    func context(total: Int, type: HandType, pair: Rank? = nil, up: Rank) -> WhyContext {
        WhyContext(handTotal: total, handType: type, pairRank: pair, dealerUpCard: up,
                   userAction: .hit, correctAction: .stand, rules: BlackjackRules())
    }

    @Test("Hand labels")
    func labels() {
        #expect(StrategyText.handLabel(context(total: 16, type: .hard, up: .king)) == "Hard 16 vs 10")
        #expect(StrategyText.handLabel(context(total: 18, type: .soft, up: .ace)) == "Soft 18 vs A")
        #expect(StrategyText.handLabel(context(total: 16, type: .pair, pair: .eight, up: .six)) == "Pair of 8s vs 6")
        #expect(StrategyText.handLabel(context(total: 12, type: .pair, pair: .ace, up: .two)) == "Pair of Aces vs 2")
        #expect(StrategyText.handLabel(context(total: 20, type: .pair, pair: .king, up: .two)) == "Pair of 10s vs 2")
    }

    @Test("Action names")
    func actionNames() {
        #expect(Action.allCases.map(StrategyText.actionName) == ["Hit", "Stand", "Double", "Split", "Surrender"])
    }

    @Test("Feedback text for correct, wrong and timeout")
    func feedback() {
        let right = StrategyText.feedback(isCorrect: true, chosen: .action(.stand), correct: .stand, label: "Hard 17 vs 10")
        #expect(right.headline == "Correct: Stand")
        #expect(right.reason == "Hard 17 vs 10")
        let wrong = StrategyText.feedback(isCorrect: false, chosen: .action(.stand), correct: .hit, label: "Hard 16 vs 10")
        #expect(wrong.headline == "The play is Hit")
        #expect(wrong.reason == "You chose Stand on hard 16 vs 10.")
        let late = StrategyText.feedback(isCorrect: false, chosen: .timeout, correct: .hit, label: "Hard 16 vs 10")
        #expect(late.headline == "Time's up")
        #expect(late.reason == "The play was Hit on hard 16 vs 10.")
    }

    @Test("Signed units use a true minus sign and trim zeros")
    func units() {
        #expect(StrategyText.signedUnits(1) == "+1")
        #expect(StrategyText.signedUnits(1.5) == "+1.5")
        #expect(StrategyText.signedUnits(-2) == "−2")
        #expect(StrategyText.signedUnits(-0.5) == "−0.5")
        #expect(StrategyText.signedUnits(0) == "±0")
    }
}
```

Test `outcomeLines` in Task 6, where real `PlayerHandState`s come from `RoundEngine`. Add to `AppShellTests.swift`:

```swift
    @Test("Strategy UI-test hooks are read only under -uiTesting")
    func strategyHooks() {
        let on = LaunchConfiguration(arguments: ["-uiTesting", "-strategyLength", "5", "-seed", "7"])
        #expect(on.strategyLength == 5)
        #expect(on.seed == 7)
        let off = LaunchConfiguration(arguments: ["-strategyLength", "5", "-seed", "7"])
        #expect(off.strategyLength == nil)
        #expect(off.seed == nil)
    }
```

- [ ] **Step 2: Run and confirm failure** (compile failure)

- [ ] **Step 3: Implement**

`StrategySetup.swift`:

```swift
import Foundation
import os
import BJSCore

/// Strategy trainer modes (parent spec §5). The raw value is stored as `Session.mode`.
enum StrategyMode: String, CaseIterable, Codable {
    case learn, test, speed, weakSpots

    var title: String {
        switch self {
        case .learn: return "Learn"
        case .test: return "Test"
        case .speed: return "Speed"
        case .weakSpots: return "Weak spots"
        }
    }

    var blurb: String {
        switch self {
        case .learn: return "The correct play is highlighted before you choose. Doesn't count towards your stats."
        case .test: return "No hints. Every decision is graded."
        case .speed: return "No hints, and a timer on every decision."
        case .weakSpots: return "No hints. Deals more of the hands you miss most."
        }
    }

    var showsHint: Bool { self == .learn }
    var isTimed: Bool { self == .speed }
    var usesWeights: Bool { self == .weakSpots }
}

enum StrategyLength: Hashable, Codable {
    case hands(Int)
    case endless

    static let options: [StrategyLength] = [.hands(25), .hands(50), .hands(100), .endless]

    var title: String {
        switch self {
        case .hands(let n): return "\(n)"
        case .endless: return "∞"
        }
    }

    var handLimit: Int? {
        switch self {
        case .hands(let n): return n
        case .endless: return nil
        }
    }
}

/// What a Strategy session deals; stored in `LastLaunch.setup` for Continue.
struct StrategySetup: Codable, Equatable {
    var mode: StrategyMode = .test
    var length: StrategyLength = .hands(25)
    var filter: HandFilter = .all

    func lastLaunch() throws -> LastLaunch {
        LastLaunch(module: .strategy, mode: mode.rawValue, setup: try JSONEncoder().encode(self))
    }

    /// nil (logged) when the data doesn't decode, e.g. after a format change.
    static func decode(_ data: Data) -> StrategySetup? {
        do {
            return try JSONDecoder().decode(StrategySetup.self, from: data)
        } catch {
            Logger(subsystem: "com.bjs.app", category: "Strategy")
                .error("Strategy setup failed to decode: \(error.localizedDescription)")
            return nil
        }
    }
}

extension HandFilter {
    var title: String {
        switch self {
        case .all: return "All"
        case .hard: return "Hard"
        case .soft: return "Soft"
        case .pairs: return "Pairs"
        }
    }
}
```

`StrategyText.swift`:

```swift
import BJSCore

/// Display strings for the Strategy trainer.
enum StrategyText {

    static func actionName(_ action: Action) -> String {
        switch action {
        case .hit: return "Hit"
        case .stand: return "Stand"
        case .double: return "Double"
        case .split: return "Split"
        case .surrender: return "Surrender"
        }
    }

    static func upcardName(_ rank: Rank) -> String {
        rank == .ace ? "A" : "\(rank.blackjackValue)"
    }

    /// "Hard 16 vs 10", "Soft 18 vs A", "Pair of 8s vs 6", "Pair of Aces vs 2".
    static func handLabel(_ c: WhyContext) -> String {
        let up = upcardName(c.dealerUpCard)
        switch c.handType {
        case .hard: return "Hard \(c.handTotal) vs \(up)"
        case .soft: return "Soft \(c.handTotal) vs \(up)"
        case .pair:
            let rank = c.pairRank ?? .two
            let name = rank == .ace ? "Aces" : "\(rank.blackjackValue)s"
            return "Pair of \(name) vs \(up)"
        }
    }

    static func feedback(isCorrect: Bool, chosen: RecordedChoice, correct: Action,
                         label: String) -> (headline: String, reason: String) {
        let lowered = label.prefix(1).lowercased() + label.dropFirst()
        switch chosen {
        case .timeout:
            return ("Time's up", "The play was \(actionName(correct)) on \(lowered).")
        case .action(let action):
            if isCorrect { return ("Correct: \(actionName(correct))", label) }
            return ("The play is \(actionName(correct))", "You chose \(actionName(action)) on \(lowered).")
        }
    }

    /// "+1", "+1.5", "−2", "−0.5", "±0".
    static func signedUnits(_ value: Double) -> String {
        if value == 0 { return "±0" }
        let magnitude = abs(value)
        let number = magnitude == magnitude.rounded() ? "\(Int(magnitude))" : "\(magnitude)"
        return (value > 0 ? "+" : "−") + number
    }

    /// One line for the dealer, then one per player hand ("Hand 2: Win +1" after splits).
    static func outcomeLines(hands: [PlayerHandState], dealer: BlackjackHand) -> [String] {
        var lines: [String] = []
        if dealer.isBlackjack {
            lines.append("Dealer blackjack")
        } else if dealer.isBust {
            lines.append("Dealer busts with \(dealer.total)")
        } else {
            lines.append("Dealer \(dealer.total)")
        }
        for (index, state) in hands.enumerated() {
            let result: String
            switch state.outcome {
            case .blackjack: result = "Blackjack"
            case .win: result = "Win"
            case .push: result = "Push"
            case .loss: result = "Lose"
            case .bust: result = "Bust"
            case .surrendered: result = "Surrender"
            case nil: result = "—"
            }
            let prefix = hands.count > 1 ? "Hand \(index + 1): " : ""
            lines.append("\(prefix)\(result) \(signedUnits(state.net))")
        }
        return lines
    }
}
```

`LaunchConfiguration`: add the properties and parse them in `init` after `isUITesting` is set:

```swift
    /// UI testing only: overrides the Strategy session length (hands).
    let strategyLength: Int?
    /// UI testing only: seeds the Strategy trainer's random number generator.
    let seed: UInt64?

    // in init:
        func value(after flag: String) -> String? {
            guard let i = arguments.firstIndex(of: flag), i + 1 < arguments.count else { return nil }
            return arguments[i + 1]
        }
        strategyLength = isUITesting ? value(after: "-strategyLength").flatMap { Int($0) } : nil
        seed = isUITesting ? value(after: "-seed").flatMap { UInt64($0) } : nil
```

The nested func can't capture `self` before init completes. It only uses `arguments`, so it is fine. If the compiler objects, make it a `private static func value(after:in:)`.

- [ ] **Step 4: Run all app tests.** Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add BJS BJSTests
git commit -m "feat(strategy): setup model, display text and UI-test launch hooks"
```

---

### Task 6: `StrategyTrainerViewModel`: dealing, grading, feedback, outcome and length

**Files:**
- Create: `BJS/Features/Strategy/StrategyTrainerViewModel.swift`
- Test: `BJSTests/Features/StrategyTrainerViewModelTests.swift`

**Interfaces:**
- Consumes: `StrategySetup`, `StrategyMode`, `StrategyText` (Task 5); `WhyContext(spot:userAction:table:rules:)` (Task 2); `SessionDraft`, `DecisionDraft`, `RecordedChoice` (Persistence).
- Produces (Task 7 extends it, and Task 9's views read it):

```swift
struct GradedDecision: Equatable, Identifiable {
    let id: Int                 // order within the session, from 0
    let handNumber: Int
    let cell: TrainingCell
    let chosen: RecordedChoice
    let correctAction: Action
    let isCorrect: Bool
    let responseMs: Int
    let decidedAt: Date
    let why: WhyContext
    let abandonsHand: Bool      // Speed timeout
    var draft: DecisionDraft { get }
}

enum TrainerPhase: Equatable { case awaitingDecision, feedback(GradedDecision), outcome, summary }

@Observable final class StrategyTrainerViewModel {
    typealias ShoeMaker = (TrainingCell, BlackjackRules, inout SeededRandomNumberGenerator) -> Shoe
    init(setup: StrategySetup, rules: BlackjackRules, weights: [TrainingCell: Double]?,
         speedTimerSeconds: Double, handLimitOverride: Int? = nil, seed: UInt64,
         now: @escaping () -> Date = { Date() }, makeShoe: ShoeMaker? = nil,
         persist: @escaping (SessionDraft) throws -> Void)
    let setup: StrategySetup; let rules: BlackjackRules; let handLimit: Int?; let speedTimerSeconds: Double
    let sessionID: UUID; let startedAt: Date
    private(set) var phase: TrainerPhase
    private(set) var round: RoundEngine?
    private(set) var handNumber: Int          // hands dealt so far (1-based for the current hand)
    private(set) var handsCompleted: Int
    private(set) var decisions: [GradedDecision]
    private(set) var decisionToken: Int       // changes whenever a new decision starts
    private(set) var decisionStartedAt: Date
    private(set) var toastCount: Int          // increments per correct, play-continues decision
    var legalActions: Set<Action> { get }
    var hint: Action? { get }
    var isDealerRevealed: Bool { get }        // phase == .outcome
    var dealerCards: [Card] { get }           // [upcard, hole] until revealed, then every card
    var playerHands: [PlayerHandState] { get }
    var activeHandIndex: Int { get }
    var outcomeLines: [String] { get }        // only meaningful in .outcome
    var correctCount: Int { get }
    var currentStreak: Int { get }
    func choose(_ action: Action)
    func next()                                // FeedbackCard NEXT
    func deal()                                // outcome DEAL
}
```

The trainer deals its first hand in `init`.

- [ ] **Step 1: Write the failing tests**

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

/// Hands out pre-built shoes in order; records the cells the trainer asked for.
@MainActor
final class ScriptedShoes {
    var shoes: [[Card]]
    var requestedCells: [TrainingCell] = []
    init(_ shoes: [[Card]]) { self.shoes = shoes }

    var maker: StrategyTrainerViewModel.ShoeMaker {
        { [self] cell, _, _ in
            requestedCells.append(cell)
            // After the script runs out, repeat the last shoe.
            let cards = shoes.count > 1 ? shoes.removeFirst() : shoes[0]
            return Shoe(orderedCards: cards)
        }
    }
}

func trainerCard(_ rank: Rank, _ suit: Suit = .spades) -> Card { Card(rank: rank, suit: suit) }

/// RoundEngine deal order: P1, upcard, P2, hole, then draws.
func shoe(player: (Rank, Rank), up: Rank, hole: Rank, draws: [Rank] = []) -> [Card] {
    [trainerCard(player.0, .spades), trainerCard(up, .hearts), trainerCard(player.1, .clubs), trainerCard(hole, .diamonds)]
        + draws.map { trainerCard($0, .spades) } + Array(repeating: trainerCard(.ten, .clubs), count: 20)
}

@MainActor
struct StrategyTrainerViewModelTests {

    var saved: [SessionDraft] = []

    func trainer(_ shoes: ScriptedShoes, mode: StrategyMode = .test, length: StrategyLength = .hands(25),
                 rules: BlackjackRules = BlackjackRules(), limit: Int? = nil,
                 weights: [TrainingCell: Double]? = nil, filter: HandFilter = .all,
                 now: @escaping () -> Date = { Date(timeIntervalSince1970: 1000) }) -> StrategyTrainerViewModel {
        StrategyTrainerViewModel(setup: StrategySetup(mode: mode, length: length, filter: filter), rules: rules,
                                 weights: weights, speedTimerSeconds: 3, handLimitOverride: limit, seed: 1,
                                 now: now, makeShoe: shoes.maker, persist: { _ in })
    }

    @Test("The first hand is dealt on init and awaits a decision")
    func dealsOnInit() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)]))
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.handNumber == 1)
        #expect(vm.playerHands.count == 1)
        #expect(vm.dealerCards.count == 2)
        #expect(!vm.isDealerRevealed)
        #expect(vm.legalActions.contains(.stand))
    }

    @Test("A wrong STAND shows feedback, and NEXT reveals the dealer")
    func wrongStand() throws {
        // Hard 16 vs 10, 6D S17 no surrender: correct play is hit. Dealer 10+7 = 17, no draw.
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)]))
        vm.choose(.stand)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(!graded.isCorrect)
        #expect(graded.correctAction == .hit)
        #expect(graded.chosen == .action(.stand))
        #expect(vm.dealerCards.count == 2)
        vm.next()
        #expect(vm.phase == .outcome)
        #expect(vm.isDealerRevealed)
        #expect(vm.outcomeLines == ["Dealer 17", "Lose −1"])
    }

    @Test("A correct STAND still shows feedback before the outcome")
    func correctStand() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)]))
        vm.choose(.stand)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
        #expect(vm.toastCount == 0)
    }

    @Test("A correct hit that keeps the hand going shows a toast, not feedback")
    func correctHitToast() {
        // Hard 9 vs 7 → hit; draws a 2 → hard 11, still deciding.
        let vm = trainer(ScriptedShoes([shoe(player: (.five, .four), up: .seven, hole: .ten, draws: [.two])]))
        let token = vm.decisionToken
        vm.choose(.hit)
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.toastCount == 1)
        #expect(vm.decisions.count == 1)
        #expect(vm.decisionToken != token)
        #expect(vm.playerHands[0].hand.total == 11)
    }

    @Test("A wrong hit that keeps the hand going shows feedback, and NEXT returns to deciding")
    func wrongHitContinues() {
        // Hard 17 vs 10 → stand; the user hits and draws an ace → 18, still deciding.
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight, draws: [.ace])]))
        vm.choose(.hit)
        guard case .feedback = vm.phase else { Issue.record("expected feedback"); return }
        vm.next()
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.playerHands[0].hand.total == 18)
    }

    @Test("A hit that busts ends the turn: feedback, then outcome")
    func hitBust() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .two), up: .two, hole: .ten, draws: [.king])]))
        vm.choose(.hit)   // hard 12 vs 2 → hit is correct, busts on K
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
        vm.next()
        #expect(vm.phase == .outcome)
        #expect(vm.outcomeLines.last == "Bust −1")
    }

    @Test("Learn mode hints the correct play; Test mode doesn't")
    func hints() {
        let cards = shoe(player: (.ten, .six), up: .ten, hole: .seven)
        #expect(trainer(ScriptedShoes([cards]), mode: .learn).hint == .hit)
        #expect(trainer(ScriptedShoes([cards]), mode: .test).hint == nil)
    }

    @Test("DEAL after the outcome deals the next hand")
    func dealNext() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight),
                                        shoe(player: (.nine, .seven), up: .six, hole: .ten)]))
        vm.choose(.stand)
        vm.next()
        vm.deal()
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.handNumber == 2)
        #expect(vm.handsCompleted == 1)
        #expect(vm.playerHands[0].hand.total == 16)
    }

    @Test("Reaching the hand limit goes to the summary")
    func handLimit() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)]), limit: 2)
        for _ in 0..<2 { vm.choose(.stand); vm.next(); vm.deal() }
        #expect(vm.phase == .summary)
        #expect(vm.handsCompleted == 2)
        #expect(vm.handLimit == 2)
    }

    @Test("Split: a correct split toasts, each split hand is played, then the dealer is revealed")
    func splitFlow() {
        // 8,8 vs 6 → split. Split cards: 10 onto the first 8, 9 onto the second.
        let vm = trainer(ScriptedShoes([shoe(player: (.eight, .eight), up: .six, hole: .ten,
                                             draws: [.ten, .nine])]))
        vm.choose(.split)
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.toastCount == 1)
        #expect(vm.playerHands.count == 2)
        #expect(vm.activeHandIndex == 0)
        vm.choose(.stand)            // 18 vs 6: correct stand, second hand still to play → toast
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.activeHandIndex == 1)
        vm.choose(.stand)            // 17 vs 6: correct, turn ends → feedback
        guard case .feedback = vm.phase else { Issue.record("expected feedback"); return }
        vm.next()
        #expect(vm.phase == .outcome)
        #expect(vm.outcomeLines.count == 3)
    }

    @Test("Grading uses the snapshot rules' composition note")
    func compositionGrading() {
        var rules = BlackjackRules()
        rules.deckCount = .one
        rules.surrenderRule = .early
        let vm = trainer(ScriptedShoes([shoe(player: (.eight, .six), up: .ten, hole: .seven)]), rules: rules)
        #expect(vm.legalActions.contains(.surrender))
        vm.choose(.surrender)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.isCorrect)
    }

    @Test("Decisions record cell, response time and WHY context")
    func decisionRecord() {
        var clock = Date(timeIntervalSince1970: 1000)
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)]), now: { clock })
        clock = clock.addingTimeInterval(1.25)
        vm.choose(.stand)
        let d = vm.decisions[0]
        #expect(d.cell == TrainingCell(handType: .hard, playerValue: 16, dealerUpcard: 10))
        #expect(d.responseMs == 1250)
        #expect(d.why.userAction == .stand)
        #expect(d.why.correctAction == .hit)
        #expect(d.draft.chosen == .action(.stand))
        #expect(d.draft.handNumber == 1)
    }

    @Test("Actions outside awaitingDecision, or illegal ones, are ignored")
    func ignoredActions() {
        let vm = trainer(ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)]))
        vm.choose(.split)              // not legal on 10,6
        #expect(vm.decisions.isEmpty)
        vm.choose(.stand)
        vm.choose(.hit)                // in feedback
        #expect(vm.decisions.count == 1)
        vm.deal()                      // not in outcome
        guard case .feedback = vm.phase else { Issue.record("expected feedback"); return }
    }

    @Test("Filter and weights reach the cell sampler")
    func sampling() {
        let pairsOnly = ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)])
        let vm = trainer(pairsOnly, limit: 10, filter: .pairs)
        for _ in 0..<9 { vm.choose(.stand); vm.next(); vm.deal() }
        #expect(pairsOnly.requestedCells.count == 10)
        #expect(pairsOnly.requestedCells.allSatisfy { $0.handType == .pair })

        let target = TrainingCell(handType: .soft, playerValue: 18, dealerUpcard: 9)
        let heavy = [target: 1000.0]
        let weighted = ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)])
        let wvm = trainer(weighted, mode: .weakSpots, limit: 20, weights: heavy)
        for _ in 0..<19 { wvm.choose(.stand); wvm.next(); wvm.deal() }
        #expect(weighted.requestedCells.filter { $0 == target }.count >= 15)

        let unweighted = ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight)])
        let tvm = trainer(unweighted, mode: .test, limit: 20, weights: heavy)
        for _ in 0..<19 { tvm.choose(.stand); tvm.next(); tvm.deal() }
        #expect(unweighted.requestedCells.filter { $0 == target }.count < 5)
    }

    /// Parent spec §7 required regression (the Phase 7 bug): STAND always produces
    /// feedback before the next hand, in every mode, with real generated hands.
    @Test("STAND regression: every turn-ending decision shows feedback before the next deal",
          arguments: StrategyMode.allCases)
    func standAlwaysFeedsBack(mode: StrategyMode) {
        for seed in UInt64(1)...UInt64(5) {
            let vm = StrategyTrainerViewModel(setup: StrategySetup(mode: mode, length: .hands(15)),
                                              rules: BlackjackRules(), weights: nil, speedTimerSeconds: 3,
                                              seed: seed, persist: { _ in })
            var hands = 0
            while vm.phase != .summary {
                let dealt = vm.handNumber
                #expect(vm.phase == .awaitingDecision)
                vm.choose(.stand)
                // Stand ends the turn unless an earlier split hand is waiting; this path never splits.
                guard case .feedback = vm.phase else {
                    Issue.record("seed \(seed) hand \(dealt): no feedback after STAND"); return
                }
                #expect(vm.handNumber == dealt, "no new hand before feedback")
                vm.next()
                #expect(vm.phase == .outcome)
                vm.deal()
                hands += 1
            }
            #expect(hands == 15)
        }
    }
}
```

`outcomeLines` is covered by `wrongStand`, `hitBust` and `splitFlow` above.

- [ ] **Step 2: Run and confirm failure** (compile failure: no `StrategyTrainerViewModel`)

- [ ] **Step 3: Implement `StrategyTrainerViewModel.swift`**

```swift
import Foundation
import Observation
import os
import BJSCore

/// One graded decision, kept in memory for feedback, WHY and the summary.
struct GradedDecision: Equatable, Identifiable {
    let id: Int
    let handNumber: Int
    let cell: TrainingCell
    let chosen: RecordedChoice
    let correctAction: Action
    let isCorrect: Bool
    let responseMs: Int
    let decidedAt: Date
    let why: WhyContext
    /// A Speed timeout: the hand is abandoned after this feedback.
    let abandonsHand: Bool

    var draft: DecisionDraft {
        DecisionDraft(handNumber: handNumber, cell: cell, chosen: chosen, correctAction: correctAction,
                      isCorrect: isCorrect, responseMs: responseMs, decidedAt: decidedAt)
    }
}

enum TrainerPhase: Equatable {
    case awaitingDecision
    case feedback(GradedDecision)
    case outcome
    case summary
}

/// Runs a Strategy session over `RoundEngine` (Step 3 spec §4). Thin: BJSCore deals, plays and
/// grades; this type sequences phases, hides the dealer until the outcome, and persists.
@Observable
final class StrategyTrainerViewModel {
    typealias ShoeMaker = (TrainingCell, BlackjackRules, inout SeededRandomNumberGenerator) -> Shoe

    static let defaultShoeMaker: ShoeMaker = { cell, rules, rng in
        HandGenerator.stackedShoe(for: cell, deckCount: rules.deckCount.rawValue,
                                  peekRule: rules.peekRule, using: &rng)
    }
    private static let engine = StrategyEngine()

    let setup: StrategySetup
    let rules: BlackjackRules
    let handLimit: Int?
    let speedTimerSeconds: Double
    let sessionID = UUID()
    let startedAt: Date

    private(set) var phase: TrainerPhase = .awaitingDecision
    private(set) var round: RoundEngine?
    private(set) var handNumber = 0
    private(set) var handsCompleted = 0
    private(set) var decisions: [GradedDecision] = []
    private(set) var decisionToken = 0
    private(set) var decisionStartedAt: Date
    private(set) var toastCount = 0

    @ObservationIgnored private let table: StrategyTable
    @ObservationIgnored private let weights: [TrainingCell: Double]?
    @ObservationIgnored private var rng: SeededRandomNumberGenerator
    @ObservationIgnored private var shoe = Shoe(orderedCards: [])
    @ObservationIgnored let now: () -> Date
    @ObservationIgnored private let makeShoe: ShoeMaker
    @ObservationIgnored let persist: (SessionDraft) throws -> Void
    @ObservationIgnored let logger = Logger(subsystem: "com.bjs.app", category: "StrategyTrainer")

    init(setup: StrategySetup, rules: BlackjackRules, weights: [TrainingCell: Double]?,
         speedTimerSeconds: Double, handLimitOverride: Int? = nil, seed: UInt64,
         now: @escaping () -> Date = { Date() }, makeShoe: ShoeMaker? = nil,
         persist: @escaping (SessionDraft) throws -> Void) {
        self.setup = setup
        self.rules = rules
        self.handLimit = handLimitOverride ?? setup.length.handLimit
        self.speedTimerSeconds = speedTimerSeconds
        self.weights = setup.mode.usesWeights ? weights : nil
        self.rng = SeededRandomNumberGenerator(seed: seed)
        self.now = now
        self.makeShoe = makeShoe ?? Self.defaultShoeMaker
        self.persist = persist
        self.table = Self.engine.strategy(for: rules)
        let start = now()
        self.startedAt = start
        self.decisionStartedAt = start
        dealNextHand()
    }

    // MARK: - Display

    var spot: DecisionSpot? { phase == .awaitingDecision ? round?.currentSpot : nil }
    var legalActions: Set<Action> { spot?.legalActions ?? [] }
    var hint: Action? {
        guard setup.mode.showsHint, let spot else { return nil }
        return table.action(for: spot)
    }
    var isDealerRevealed: Bool { phase == .outcome }
    var dealerCards: [Card] {
        guard let round else { return [] }
        return isDealerRevealed ? round.dealer.cards : Array(round.dealer.cards.prefix(2))
    }
    var playerHands: [PlayerHandState] { round?.hands ?? [] }
    var activeHandIndex: Int { round?.activeHandIndex ?? 0 }
    var outcomeLines: [String] {
        guard let round else { return [] }
        return StrategyText.outcomeLines(hands: round.hands, dealer: round.dealer)
    }
    var correctCount: Int { decisions.filter { $0.isCorrect }.count }
    var currentStreak: Int {
        var run = 0
        for d in decisions.reversed() {
            guard d.isCorrect else { break }
            run += 1
        }
        return run
    }

    // MARK: - Input

    func choose(_ action: Action) {
        guard phase == .awaitingDecision, var round, let spot = round.currentSpot,
              spot.legalActions.contains(action) else { return }
        let decidedAt = now()
        let correct = table.action(for: spot)
        let graded = GradedDecision(
            id: decisions.count, handNumber: handNumber, cell: TrainingCell(spot: spot),
            chosen: .action(action), correctAction: correct, isCorrect: action == correct,
            responseMs: Self.milliseconds(from: decisionStartedAt, to: decidedAt), decidedAt: decidedAt,
            why: WhyContext(spot: spot, userAction: action, table: table, rules: rules),
            abandonsHand: false)
        decisions.append(graded)
        do {
            try round.apply(action, shoe: &shoe)
        } catch {
            logger.error("RoundEngine rejected \(action.rawValue): \(String(describing: error))")
        }
        self.round = round
        if !graded.isCorrect || round.phase != .playerTurn {
            phase = .feedback(graded)
        } else {
            toastCount += 1
            beginDecision()
        }
    }

    /// FeedbackCard NEXT.
    func next() {
        guard case .feedback(let graded) = phase, let round else { return }
        if graded.abandonsHand {
            completeHand()
        } else if round.phase == .playerTurn {
            beginDecision()
        } else {
            phase = .outcome
        }
    }

    /// Outcome DEAL.
    func deal() {
        guard phase == .outcome else { return }
        completeHand()
    }

    // MARK: - Internals

    func completeHand() {
        handsCompleted += 1
        if let handLimit, handsCompleted >= handLimit {
            finish()
        } else {
            dealNextHand()
        }
    }

    private func dealNextHand() {
        handNumber += 1
        let cell = HandGenerator.sampleCell(filter: setup.filter, weights: weights, using: &rng)
        shoe = makeShoe(cell, rules, &rng)
        do {
            let fresh = try RoundEngine(rules: rules, shoe: &shoe)
            round = fresh
            if fresh.phase == .settled {
                phase = .outcome
            } else {
                beginDecision()
            }
        } catch {
            logger.error("Could not deal a training hand: \(String(describing: error))")
            finish()
        }
    }

    func beginDecision() {
        decisionToken += 1
        decisionStartedAt = now()
        phase = .awaitingDecision
    }

    /// Ends the session: shows the summary. Task 7 adds saving.
    func finish() {
        guard phase != .summary else { return }
        phase = .summary
    }

    static func milliseconds(from start: Date, to end: Date) -> Int {
        max(0, Int((end.timeIntervalSince(start) * 1000).rounded()))
    }
}
```

`decisionToken` is observed, so the view's `.task(id:)` restarts the Speed timer for each new decision.

- [ ] **Step 4: Run the tests**

Run: `… -only-testing:BJSTests/StrategyTrainerViewModelTests`, then the full app suite.
Expected: all pass. If a scripted hand's expected correct action differs from the chart, check it against `StrategyEngine().strategy(for: BlackjackRules())` and fix the **test's hand**, never the engine, with a comment citing the chart cell.

- [ ] **Step 5: Commit**

```bash
git add BJS BJSTests
git commit -m "feat(strategy): trainer view model with feedback-before-outcome phase machine"
```

---

### Task 7: Trainer: Speed timeout, finishing and saving, summary numbers

**Files:**
- Modify: `BJS/Features/Strategy/StrategyTrainerViewModel.swift`
- Test: `BJSTests/Features/StrategySessionTests.swift`

**Interfaces:**
- Consumes: Task 6's view model (`finish()`, `completeHand()`, `beginDecision()`, `persist`, `now`, `logger`).
- Produces:
  - `func timeoutElapsed(token: Int)`;
  - `func finish()` (now also saves);
  - `private(set) var hasSaved: Bool`, `private(set) var saveFailed: Bool`, `private(set) var endedAt: Date?`;
  - `var canSavePartial: Bool`;
  - `var sessionDraft: SessionDraft`;
  - `var summary: StrategySessionSummary`, where:

```swift
struct StrategySessionSummary: Equatable {
    let accuracy: Double?           // nil with no decisions
    let decisionCount: Int
    let mistakes: [GradedDecision]  // in order
    let bestStreak: Int
    let handsPlayed: Int            // hands with at least one decision
    let averageDecisionMs: Double?  // Speed mode only
}
```

- [ ] **Step 1: Write the failing tests**

```swift
import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
final class SaveSpy {
    var drafts: [SessionDraft] = []
    var error: Error?
    func persist(_ d: SessionDraft) throws {
        if let error { throw error }
        drafts.append(d)
    }
}

struct SaveFailure: Error {}

@MainActor
struct StrategySessionTests {

    func make(_ spy: SaveSpy, mode: StrategyMode = .test, length: StrategyLength = .hands(25),
              limit: Int? = nil, shoes: ScriptedShoes? = nil,
              now: @escaping () -> Date = { Date(timeIntervalSince1970: 1000) }) -> StrategyTrainerViewModel {
        let s = shoes ?? ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven)])
        return StrategyTrainerViewModel(setup: StrategySetup(mode: mode, length: length), rules: BlackjackRules(),
                                        weights: nil, speedTimerSeconds: 3, handLimitOverride: limit, seed: 1,
                                        now: now, makeShoe: s.maker, persist: { try spy.persist($0) })
    }

    @Test("A Speed timeout records a wrong 'timeout', then NEXT abandons the hand")
    func timeout() {
        let spy = SaveSpy()
        let vm = make(spy, mode: .speed,
                      shoes: ScriptedShoes([shoe(player: (.ten, .six), up: .ten, hole: .seven),
                                            shoe(player: (.ten, .seven), up: .nine, hole: .eight)]))
        vm.timeoutElapsed(token: vm.decisionToken)
        guard case .feedback(let graded) = vm.phase else { Issue.record("expected feedback"); return }
        #expect(graded.chosen == .timeout)
        #expect(!graded.isCorrect)
        #expect(graded.abandonsHand)
        #expect(graded.responseMs == 3000)
        #expect(graded.why.userAction == nil)
        vm.next()
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.handNumber == 2)
        #expect(vm.handsCompleted == 1)
    }

    @Test("A stale timer token is ignored")
    func staleToken() {
        let vm = make(SaveSpy(), mode: .speed)
        let stale = vm.decisionToken - 1
        vm.timeoutElapsed(token: stale)
        #expect(vm.phase == .awaitingDecision)
        #expect(vm.decisions.isEmpty)
    }

    @Test("A timeout during feedback is ignored")
    func timeoutDuringFeedback() {
        let vm = make(SaveSpy(), mode: .speed)
        let token = vm.decisionToken
        vm.choose(.stand)
        vm.timeoutElapsed(token: token)
        #expect(vm.decisions.count == 1)
    }

    @Test("A timeout on the last hand goes to the summary")
    func timeoutLastHand() {
        let vm = make(SaveSpy(), mode: .speed, limit: 1)
        vm.timeoutElapsed(token: vm.decisionToken)
        vm.next()
        #expect(vm.phase == .summary)
    }

    @Test("Finishing a session saves it exactly once, with decisions in order")
    func saveOnce() throws {
        let spy = SaveSpy()
        let vm = make(spy, limit: 2)
        for _ in 0..<2 { vm.choose(.stand); vm.next(); vm.deal() }
        #expect(vm.phase == .summary)
        vm.finish()
        #expect(spy.drafts.count == 1)
        let draft = try #require(spy.drafts.first)
        #expect(draft.id == vm.sessionID)
        #expect(draft.module == .strategy)
        #expect(draft.mode == "test")
        #expect(draft.decisions.map { $0.handNumber } == [1, 2])
        #expect(draft.rules == BlackjackRules())
        #expect(vm.hasSaved)
    }

    @Test("Save partial mid-session saves what was graded and shows the summary")
    func savePartial() {
        let spy = SaveSpy()
        let vm = make(spy)
        #expect(!vm.canSavePartial)
        vm.choose(.stand)
        #expect(vm.canSavePartial)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(spy.drafts.count == 1)
        #expect(spy.drafts[0].decisions.count == 1)
        #expect(!vm.canSavePartial)
    }

    @Test("Finishing with no decisions shows the summary without saving")
    func finishEmpty() {
        let spy = SaveSpy()
        let vm = make(spy, length: .endless)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(spy.drafts.isEmpty)
    }

    @Test("A failed save flags the error and still shows the summary")
    func saveFailure() {
        let spy = SaveSpy()
        spy.error = SaveFailure()
        let vm = make(spy)
        vm.choose(.stand)
        vm.finish()
        #expect(vm.phase == .summary)
        #expect(vm.saveFailed)
        vm.finish()
        #expect(spy.drafts.isEmpty)
    }

    @Test("Summary numbers; average decision time only in Speed mode")
    func summary() {
        var clock = Date(timeIntervalSince1970: 1000)
        let shoes = ScriptedShoes([shoe(player: (.ten, .seven), up: .ten, hole: .eight),   // stand correct
                                   shoe(player: (.ten, .six), up: .ten, hole: .seven),     // stand wrong
                                   shoe(player: (.ten, .seven), up: .ten, hole: .eight)])  // stand correct
        for mode in [StrategyMode.test, .speed] {
            let s = ScriptedShoes(shoes.shoes)
            let vm = make(SaveSpy(), mode: mode, limit: 3, shoes: s, now: { clock })
            for _ in 0..<3 {
                clock = clock.addingTimeInterval(2)
                vm.choose(.stand); vm.next(); vm.deal()
            }
            let sum = vm.summary
            #expect(sum.decisionCount == 3)
            #expect(sum.accuracy == 2.0 / 3.0)
            #expect(sum.mistakes.count == 1)
            #expect(sum.bestStreak == 1)
            #expect(sum.handsPlayed == 3)
            #expect(sum.averageDecisionMs == (mode == .speed ? 2000 : nil))
        }
    }

    @Test("Summary with no decisions has no accuracy")
    func emptySummary() {
        let vm = make(SaveSpy())
        #expect(vm.summary.accuracy == nil)
        #expect(vm.summary.handsPlayed == 0)
    }
}
```

- [ ] **Step 2: Run and confirm failure** (compile failure)

- [ ] **Step 3: Implement**

Add to `StrategyTrainerViewModel`:

```swift
    private(set) var hasSaved = false
    private(set) var saveFailed = false
    private(set) var endedAt: Date?

    var canSavePartial: Bool { !decisions.isEmpty && phase != .summary }

    /// Speed mode: the view's timer fired for the decision identified by `token`.
    func timeoutElapsed(token: Int) {
        guard phase == .awaitingDecision, token == decisionToken, let spot = round?.currentSpot else { return }
        let graded = GradedDecision(
            id: decisions.count, handNumber: handNumber, cell: TrainingCell(spot: spot), chosen: .timeout,
            correctAction: table.action(for: spot), isCorrect: false,
            responseMs: Int((speedTimerSeconds * 1000).rounded()), decidedAt: now(),
            why: WhyContext(spot: spot, userAction: nil, table: table, rules: rules),
            abandonsHand: true)
        decisions.append(graded)
        phase = .feedback(graded)
    }

    var sessionDraft: SessionDraft {
        SessionDraft(id: sessionID, module: .strategy, mode: setup.mode.rawValue, startedAt: startedAt,
                     endedAt: endedAt ?? now(), rules: rules, decisions: decisions.map { $0.draft })
    }

    var summary: StrategySessionSummary {
        let core = SessionSummary(decisions: decisions.map { ($0.isCorrect, $0.responseMs) }, countChecks: [])
        return StrategySessionSummary(
            accuracy: decisions.isEmpty ? nil : Double(core.correctDecisions) / Double(core.decisionCount),
            decisionCount: core.decisionCount,
            mistakes: decisions.filter { !$0.isCorrect },
            bestStreak: core.bestStreak,
            handsPlayed: Set(decisions.map { $0.handNumber }).count,
            averageDecisionMs: setup.mode.isTimed ? core.meanResponseMs : nil)
    }
```

Replace `finish()`:

```swift
    /// Ends the session (length reached, END, or Save partial): shows the summary and saves once.
    /// A session with no graded decisions isn't saved.
    func finish() {
        guard phase != .summary else { return }
        endedAt = now()
        phase = .summary
        guard !decisions.isEmpty, !hasSaved else { return }
        hasSaved = true
        do {
            try persist(sessionDraft)
        } catch {
            saveFailed = true
            logger.error("Strategy session failed to save: \(error.localizedDescription)")
        }
    }
```

`hasSaved` is set before the attempt, so a failed save is never retried into a duplicate upsert. That matches the handoff's orphan-risk note.

Add `StrategySessionSummary` (the struct from **Interfaces**) to the same file. Note that `canSavePartial` has changed; Task 6's tests don't use it.

- [ ] **Step 4: Run all app tests.** Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add BJS BJSTests
git commit -m "feat(strategy): speed timeout, save-once finishing and session summary"
```

---

### Task 8: New Felt components: FlipCard, FeltToast, CountdownBar, SplitHandsView

**Files:**
- Create:
  - `BJS/Design/Components/FlipCard.swift`
  - `BJS/Design/Components/FeltToast.swift`
  - `BJS/Design/Components/CountdownBar.swift`
  - `BJS/Design/Components/SplitHandsView.swift`
- Modify: `BJS/Design/Catalogue/FeltCatalogue.swift`: add `section("Strategy components") { strategyComponents }` after "Feedback".
- Test: `BJSTests/Design/StrategyComponentTests.swift`

**Interfaces:**
- Produces:
  - `FlipCard(card: Card, isFaceUp: Bool, width: CGFloat)`;
  - `FeltToast(text: String)` and `FeltToast.displayDuration: Double` (0.8);
  - `CountdownProgress.remainingFraction(startedAt:now:duration:) -> Double`;
  - `CountdownProgress.isUrgent(startedAt:now:duration:) -> Bool` (≤ 1 s left);
  - `CountdownBar(startedAt: Date, duration: Double)`;
  - `SplitHandsLayout.cardWidth(handCount:cardsPerHand:availableWidth:) -> CGFloat`, with `maxCardWidth` 76, `minCardWidth` 30, overlap 0.55 and spacing `FeltSpacing.m`;
  - `SplitHandsView(hands: [[Card]], totals: [String], activeIndex: Int?, availableWidth: CGFloat)`.

Use existing tokens only (`FeltColor`, `FeltType`, `FeltSpacing`, `FeltRadius`, `FeltMotion`). Do not modify `PlayingCard`, `HandView` or any existing component.

- [ ] **Step 1: Write the failing tests**

```swift
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
```

- [ ] **Step 2: Run and confirm failure**

- [ ] **Step 3: Implement**

`FlipCard.swift`:

```swift
import SwiftUI
import BJSCore

/// A card that reveals itself: a 3D flip over `FeltMotion.flip`, or a cross-fade under Reduce Motion.
struct FlipCard: View {
    let card: Card
    let isFaceUp: Bool
    let width: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch FeltMotion.revealStyle(reduceMotion: reduceMotion) {
            case .crossFade:
                ZStack {
                    PlayingCard(card: card, isFaceUp: false, width: width).opacity(isFaceUp ? 0 : 1)
                    PlayingCard(card: card, isFaceUp: true, width: width).opacity(isFaceUp ? 1 : 0)
                }
                .animation(FeltMotion.ui, value: isFaceUp)
            case .flip:
                ZStack {
                    PlayingCard(card: card, isFaceUp: false, width: width)
                        .rotation3DEffect(.degrees(isFaceUp ? -180 : 0), axis: (x: 0, y: 1, z: 0))
                        .opacity(isFaceUp ? 0 : 1)
                    PlayingCard(card: card, isFaceUp: true, width: width)
                        .rotation3DEffect(.degrees(isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                        .opacity(isFaceUp ? 1 : 0)
                }
                .animation(FeltMotion.flip, value: isFaceUp)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(PlayingCard.accessibilityText(card: card, isFaceUp: isFaceUp))
    }
}
```

`FeltToast.swift`:

```swift
import SwiftUI

/// A brief ✓ pill for a correct decision that doesn't need the full FeedbackCard.
/// The caller shows it for `displayDuration` and posts a VoiceOver announcement.
struct FeltToast: View {
    let text: String

    static let displayDuration: Double = 0.8

    var body: some View {
        HStack(spacing: FeltSpacing.s) {
            Image(systemName: "checkmark")
                .font(.body.weight(.bold))
                .foregroundStyle(FeltColor.correct)
            Text(text)
                .feltText(.body)
                .foregroundStyle(FeltColor.textPrimary)
        }
        .padding(.horizontal, FeltSpacing.l)
        .padding(.vertical, FeltSpacing.s)
        .background(FeltColor.surfaceInset, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}
```

`CountdownBar.swift`:

```swift
import SwiftUI

enum CountdownProgress {
    static func remainingFraction(startedAt: Date, now: Date, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(startedAt)
        return min(max(1 - elapsed / duration, 0), 1)
    }

    static func isUrgent(startedAt: Date, now: Date, duration: Double) -> Bool {
        duration - now.timeIntervalSince(startedAt) <= 1
    }
}

/// Speed mode's per-decision timer: a thin bar draining from cream, turning `incorrect` in the
/// last second. Under Reduce Motion it updates in half-second steps instead of continuously.
struct CountdownBar: View {
    let startedAt: Date
    let duration: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(reduceMotion ? .periodic(from: startedAt, by: 0.5) : .animation) { context in
            let fraction = CountdownProgress.remainingFraction(startedAt: startedAt, now: context.date, duration: duration)
            let urgent = CountdownProgress.isUrgent(startedAt: startedAt, now: context.date, duration: duration)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(FeltColor.surfaceInset)
                    Capsule()
                        .fill(urgent ? FeltColor.incorrect : FeltColor.cream)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
            .accessibilityElement()
            .accessibilityLabel("Time left")
            .accessibilityValue("\(Int((fraction * duration).rounded(.up))) seconds")
        }
    }
}
```

The `TimelineView` schedule types differ (`PeriodicTimelineSchedule` vs `AnimationTimelineSchedule`). If the ternary doesn't type-check, branch with `if reduceMotion { TimelineView(.periodic…) { bar($0.date) } } else { TimelineView(.animation) { bar($0.date) } }`, using a private `bar(_ date: Date) -> some View`.

`SplitHandsView.swift`:

```swift
import SwiftUI
import BJSCore

enum SplitHandsLayout {
    static let maxCardWidth: CGFloat = 76
    static let minCardWidth: CGFloat = 30
    static let overlap: CGFloat = 0.55

    /// The widest card that fits `handCount` hands of `cardsPerHand` overlapping cards side by side.
    static func cardWidth(handCount: Int, cardsPerHand: Int, availableWidth: CGFloat) -> CGFloat {
        let count = CGFloat(max(handCount, 1))
        let perHand = (availableWidth - (count - 1) * FeltSpacing.m) / count
        let factor = 1 + CGFloat(max(cardsPerHand, 1) - 1) * (1 - overlap)
        return min(maxCardWidth, max(minCardWidth, perHand / factor))
    }
}

/// One to four player hands side by side. After a split the active hand carries a brass underline.
struct SplitHandsView: View {
    let hands: [[Card]]
    let totals: [String]
    let activeIndex: Int?
    let availableWidth: CGFloat

    var body: some View {
        let cardsPerHand = max(3, hands.map { $0.count }.max() ?? 0)
        let width = SplitHandsLayout.cardWidth(handCount: hands.count, cardsPerHand: cardsPerHand,
                                               availableWidth: availableWidth)
        HStack(alignment: .top, spacing: FeltSpacing.m) {
            ForEach(Array(hands.enumerated()), id: \.offset) { index, cards in
                let isActive = hands.count > 1 && index == activeIndex
                VStack(spacing: FeltSpacing.s) {
                    HandView(cards: cards, cardWidth: width, overlap: SplitHandsLayout.overlap,
                             totalLabel: index < totals.count ? totals[index] : nil)
                    Capsule()
                        .fill(isActive ? FeltColor.brass : .clear)
                        .frame(height: 3)
                }
                .fixedSize()
                .accessibilityElement(children: .contain)
                .accessibilityLabel(hands.count > 1 ? "Hand \(index + 1) of \(hands.count)" : "Your hand")
                .accessibilityValue(isActive ? "Active" : "")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
```

In `FeltCatalogue`, add `strategyComponents`:
- `FlipCard` face down and face up;
- `FeltToast(text: "Correct")`;
- `CountdownBar(startedAt: .now, duration: 3)`;
- `SplitHandsView` with 1 hand and with 3 hands (index 1 active, width 343).

Use `@State private var flipped = false` with a "Flip" button to demo the animation.

- [ ] **Step 4: Run all app tests.** Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add BJS BJSTests
git commit -m "feat(design): FlipCard, FeltToast, CountdownBar and SplitHandsView components"
```

---

### Task 9: Strategy screens and wiring

**Files:**
- Create in `BJS/Features/Strategy/`:
  - `StrategyFlowView.swift`
  - `StrategySetupView.swift`
  - `StrategyTrainerView.swift`
  - `DealerHandView.swift`
  - `WhySheet.swift`
  - `StrategySummaryView.swift`
- Modify: `BJS/App/ModuleHost.swift` (strategy → `StrategyFlowView`)
- Create: `BJS/Shared/PercentText.swift`. Modify: `BJS/Features/Hub/HubViewModel.swift` (`percent` delegates to it).

**Interfaces:**
- Consumes everything from Tasks 4–8: `ModuleLaunch`, `LaunchConfiguration.strategyLength/seed`, `StrategySetup`, `StrategyText`, `StrategyTrainerViewModel`, `StrategySessionSummary`, `FlipCard`, `FeltToast`, `CountdownBar`, `SplitHandsView`, and the environment stores `ActiveRulesStore`, `PreferencesStore`, `SessionStore`.
- Produces: `StrategyFlowView(initialSetup: StrategySetup?, handLimitOverride: Int?, seed: UInt64?, onClose: () -> Void)`.
- Accessibility identifiers used by the UI test:
  - `hub.tile.strategy` (Task 4);
  - `strategy.start`;
  - the dock buttons, found by label `STAND` and so on;
  - the FeedbackCard `NEXT` button, found by label;
  - `strategy.deal`;
  - `strategy.summary`;
  - `strategy.close`.

The views are thin and have no unit tests. Behaviour is covered by the ViewModel tests (Tasks 6–7) and by the UI test and design check (Task 10). Build them only from Felt components and tokens.

- [ ] **Step 1: `StrategyFlowView`**

```swift
import os
import SwiftUI
import BJSCore

/// Setup → trainer → summary for one full-screen Strategy launch.
struct StrategyFlowView: View {
    /// Non-nil (Continue): start the trainer straight away with this setup.
    let initialSetup: StrategySetup?
    var handLimitOverride: Int? = nil
    var seed: UInt64? = nil
    let onClose: () -> Void

    @Environment(ActiveRulesStore.self) private var rulesStore
    @Environment(PreferencesStore.self) private var preferences
    @Environment(SessionStore.self) private var sessionStore
    @State private var setup = StrategySetup()
    @State private var trainer: StrategyTrainerViewModel?
    @State private var weights: [TrainingCell: Double]?
    @State private var didAutoStart = false

    private let logger = Logger(subsystem: "com.bjs.app", category: "StrategyFlow")

    var body: some View {
        ZStack {
            FeltBackground()
            if let trainer {
                StrategyTrainerView(model: trainer, onClose: onClose, onAgain: { start(trainer.setup) })
                    .id(trainer.sessionID)
            } else {
                StrategySetupView(setup: $setup, weakSpotsReady: weights != nil,
                                  onStart: { start(setup) }, onClose: onClose)
            }
        }
        .task(id: sessionStore.revision) { loadWeights() }
        .task {
            guard let initialSetup, !didAutoStart else { return }
            didAutoStart = true
            setup = initialSetup
            loadWeights()
            start(initialSetup)
        }
    }

    private func loadWeights() {
        do {
            weights = WeakSpotWeights.compute(from: try sessionStore.decisionSamples(modules: [.strategy, .shoe]))
        } catch {
            logger.error("Weak-spot history failed to load: \(error.localizedDescription)")
            weights = nil
        }
    }

    private func start(_ setup: StrategySetup) {
        do {
            preferences.lastLaunch = try setup.lastLaunch()
        } catch {
            logger.error("lastLaunch failed to encode: \(error.localizedDescription)")
        }
        let store = sessionStore
        trainer = StrategyTrainerViewModel(
            setup: setup, rules: rulesStore.rules, weights: weights,
            speedTimerSeconds: preferences.speedTimerSeconds, handLimitOverride: handLimitOverride,
            seed: seed ?? UInt64.random(in: .min ... .max),
            persist: { try store.save($0) })
    }
}
```

- [ ] **Step 2: `StrategySetupView`**

```swift
import SwiftUI
import BJSCore

struct StrategySetupView: View {
    @Binding var setup: StrategySetup
    let weakSpotsReady: Bool
    let onStart: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                HStack {
                    Text("Strategy").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                    Spacer()
                    CloseButton(action: onClose)
                }
                group("Mode") {
                    ModePicker(options: StrategyMode.allCases, selection: $setup.mode) { $0.title }
                    Text(setup.mode.blurb).feltText(.body).foregroundStyle(FeltColor.textSecondary)
                    if setup.mode == .weakSpots && !weakSpotsReady {
                        Text("Not enough history yet: hands are dealt evenly.")
                            .feltText(.body).foregroundStyle(FeltColor.brass)
                    }
                }
                group("Length") {
                    ModePicker(options: StrategyLength.options, selection: $setup.length) { $0.title }
                }
                group("Hands") {
                    ModePicker(options: HandFilter.allCases, selection: $setup.filter) { $0.title }
                }
                PrimaryButton(title: "Start", action: onStart)
                    .accessibilityIdentifier("strategy.start")
            }
            .padding(FeltSpacing.l)
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FeltSpacing.s) {
            Text(title).feltText(.label).foregroundStyle(FeltColor.textTertiary)
            content()
        }
    }
}

/// The × used on Strategy screens (not a Felt component; built from tokens).
struct CloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(FeltColor.textSecondary)
                .frame(width: FeltTapTarget.minimum, height: FeltTapTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
        .accessibilityIdentifier("strategy.close")
    }
}
```

`$setup.mode` forms a key path on an app type through `Binding`'s dynamic member lookup. That is fine inside a view. If the compiler complains, mark `StrategySetup`, `StrategyMode` and `StrategyLength` `nonisolated`.

- [ ] **Step 3: `DealerHandView`**

```swift
import SwiftUI
import BJSCore

/// The dealer's cards: the hole card flips at the outcome; later draws deal in.
struct DealerHandView: View {
    let cards: [Card]
    let isRevealed: Bool
    let total: Int?
    let cardWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let offsets = HandLayout.offsets(count: cards.count, cardWidth: cardWidth, overlap: 0.55)
        VStack(spacing: FeltSpacing.s) {
            ZStack(alignment: .topLeading) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    Group {
                        if index == 1 {
                            FlipCard(card: card, isFaceUp: isRevealed, width: cardWidth)
                        } else {
                            PlayingCard(card: card, width: cardWidth)
                        }
                    }
                    .offset(x: offsets[index])
                    .transition(FeltMotion.dealTransition(reduceMotion: reduceMotion))
                }
            }
            .frame(width: HandLayout.totalWidth(count: cards.count, cardWidth: cardWidth, overlap: 0.55),
                   height: PlayingCardMetrics.height(forWidth: cardWidth), alignment: .topLeading)
            .animation(FeltMotion.deal, value: cards.count)
            Text(total.map { "\($0)" } ?? " ")
                .feltText(.stat).foregroundStyle(FeltColor.textPrimary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Dealer")
    }
}
```

- [ ] **Step 4: `StrategyTrainerView`**

Layout, top to bottom, on `FeltBackground` (supplied by the flow):
- top bar: `CloseButton`; hand counter "Hand 3 / 25" (or "Hand 3" for Endless) in `.label` style; the score "12 / 14" in `.stat` style; an END `SecondaryButton` for Endless;
- `CountdownBar` in Speed mode while awaiting a decision;
- the dealer;
- `SplitHandsView`;
- the toast overlay;
- the bottom area, by phase.

```swift
import SwiftUI
import BJSCore

struct StrategyTrainerView: View {
    @Bindable var model: StrategyTrainerViewModel
    let onClose: () -> Void
    let onAgain: () -> Void

    @Environment(PreferencesStore.self) private var preferences
    @State private var showsToast = false
    @State private var showsLeaveDialog = false
    @State private var whyContext: WhyContext?

    var body: some View {
        if model.phase == .summary {
            StrategySummaryView(summary: model.summary, handsTarget: model.handLimit, mode: model.setup.mode,
                                saveFailed: model.saveFailed, onWhy: { whyContext = $0.why },
                                onAgain: onAgain, onDone: onClose)
                .sheet(item: $whyContext) { WhySheet(context: $0) }
        } else {
            table
        }
    }

    private var table: some View {
        GeometryReader { geo in
            VStack(spacing: FeltSpacing.l) {
                topBar
                if model.setup.mode.isTimed && model.phase == .awaitingDecision {
                    CountdownBar(startedAt: model.decisionStartedAt, duration: model.speedTimerSeconds)
                }
                DealerHandView(cards: model.dealerCards, isRevealed: model.isDealerRevealed,
                               total: model.isDealerRevealed ? model.round?.dealer.total : nil,
                               cardWidth: SplitHandsLayout.maxCardWidth)
                Spacer(minLength: 0)
                SplitHandsView(hands: model.playerHands.map { $0.hand.cards },
                               totals: model.playerHands.map { "\($0.hand.total)" },
                               activeIndex: model.phase == .awaitingDecision ? model.activeHandIndex : nil,
                               availableWidth: geo.size.width - 2 * FeltSpacing.l)
                Spacer(minLength: 0)
                bottom
            }
            .padding(.horizontal, FeltSpacing.l)
            .overlay(alignment: .top) {
                if showsToast {
                    FeltToast(text: "Correct").padding(.top, 56).transition(.opacity)
                }
            }
        }
        .task(id: model.decisionToken) { await runSpeedTimer() }
        .onChange(of: model.toastCount) { flashToast() }
        .sensoryFeedback(trigger: model.decisions.count) { _, _ in
            guard preferences.hapticsEnabled, let last = model.decisions.last else { return nil }
            return last.isCorrect ? .success : .error
        }
        .confirmationDialog("Leave this session?", isPresented: $showsLeaveDialog, titleVisibility: .visible) {
            Button("Save partial") { model.finish() }
            Button("Discard", role: .destructive, action: onClose)
            Button("Keep playing", role: .cancel) {}
        }
        .sheet(item: $whyContext) { WhySheet(context: $0) }
    }

    private var topBar: some View {
        HStack(spacing: FeltSpacing.m) {
            CloseButton {
                if model.canSavePartial { showsLeaveDialog = true } else { onClose() }
            }
            Text(model.handLimit.map { "Hand \(model.handNumber) / \($0)" } ?? "Hand \(model.handNumber)")
                .feltText(.label).foregroundStyle(FeltColor.textTertiary)
            Spacer()
            Text("\(model.correctCount) / \(model.decisions.count)")
                .feltText(.stat).foregroundStyle(FeltColor.textPrimary)
                .accessibilityLabel("Correct")
                .accessibilityValue("\(model.correctCount) of \(model.decisions.count)")
            if model.handLimit == nil {
                Button("END") {
                    if model.decisions.isEmpty { onClose() } else { model.finish() }
                }
                .feltText(.label).foregroundStyle(FeltColor.textPrimary)
                .frame(minWidth: FeltTapTarget.minimum, minHeight: FeltTapTarget.minimum)
                .accessibilityIdentifier("strategy.end")
            }
        }
    }

    @ViewBuilder private var bottom: some View {
        switch model.phase {
        case .awaitingDecision:
            ActionDock(legal: model.legalActions, hint: model.hint) { model.choose($0) }
        case .feedback(let graded):
            let text = StrategyText.feedback(isCorrect: graded.isCorrect, chosen: graded.chosen,
                                             correct: graded.correctAction,
                                             label: StrategyText.handLabel(graded.why))
            FeedbackCard(verdict: graded.isCorrect ? .correct : .incorrect, headline: text.headline,
                         reason: text.reason, onWhy: { whyContext = graded.why }, onNext: { model.next() })
                .padding(.horizontal, -FeltSpacing.l)
        case .outcome:
            VStack(spacing: FeltSpacing.m) {
                ForEach(model.outcomeLines, id: \.self) { line in
                    Text(line).feltText(.title).foregroundStyle(FeltColor.textPrimary)
                }
                PrimaryButton(title: "DEAL") { model.deal() }
                    .accessibilityIdentifier("strategy.deal")
            }
            .padding(.bottom, FeltSpacing.l)
        case .summary:
            EmptyView()
        }
    }

    private func runSpeedTimer() async {
        guard model.setup.mode.isTimed, model.phase == .awaitingDecision else { return }
        let token = model.decisionToken
        try? await Task.sleep(for: .seconds(model.speedTimerSeconds))
        guard !Task.isCancelled else { return }
        model.timeoutElapsed(token: token)
    }

    private func flashToast() {
        withAnimation(FeltMotion.ui) { showsToast = true }
        AccessibilityNotification.Announcement("Correct").post()
        Task {
            try? await Task.sleep(for: .seconds(FeltToast.displayDuration))
            withAnimation(FeltMotion.ui) { showsToast = false }
        }
    }
}
```

`WhyContext` is `Identifiable`, so `.sheet(item:)` works. `ForEach(model.outcomeLines, id: \.self)` forms a key path on `String`, which is not an app type, so it is fine.

- [ ] **Step 5: `WhySheet`**

```swift
import SwiftUI
import BJSCore

struct WhySheet: View {
    let context: WhyContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FeltBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: FeltSpacing.l) {
                    HStack {
                        Text(StrategyText.handLabel(context)).feltText(.display).foregroundStyle(FeltColor.textPrimary)
                        Spacer()
                        CloseButton { dismiss() }
                    }
                    HStack(spacing: FeltSpacing.s) {
                        StatChip(label: "Your play",
                                 value: context.userAction.map(StrategyText.actionName) ?? "Time's up")
                        StatChip(label: "Correct play", value: StrategyText.actionName(context.correctAction))
                    }
                    Text(WhyExplanation.explain(context))
                        .feltText(.body).foregroundStyle(FeltColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(RulesSummary.text(for: context.rules))
                        .feltText(.label).foregroundStyle(FeltColor.textTertiary)
                }
                .padding(FeltSpacing.l)
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("strategy.why")
    }
}
```

- [ ] **Step 6: `StrategySummaryView`**

```swift
import SwiftUI
import BJSCore

struct StrategySummaryView: View {
    let summary: StrategySessionSummary
    let handsTarget: Int?
    let mode: StrategyMode
    let saveFailed: Bool
    let onWhy: (GradedDecision) -> Void
    let onAgain: () -> Void
    let onDone: () -> Void

    @State private var showsSaveAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FeltSpacing.xl) {
                Text("Session summary").feltText(.display).foregroundStyle(FeltColor.textPrimary)
                    .accessibilityIdentifier("strategy.summary")
                LazyVGrid(columns: [GridItem(.flexible(), spacing: FeltSpacing.s),
                                    GridItem(.flexible(), spacing: FeltSpacing.s)], spacing: FeltSpacing.s) {
                    StatChip(label: "Accuracy", value: PercentText.text(summary.accuracy))
                    StatChip(label: "Mistakes", value: "\(summary.mistakes.count)")
                    StatChip(label: "Best streak", value: "\(summary.bestStreak)")
                    StatChip(label: "Hands", value: "\(summary.handsPlayed)")
                    if let ms = summary.averageDecisionMs {
                        StatChip(label: "Avg decision", value: String(format: "%.1f s", ms / 1000))
                    }
                }
                if !summary.mistakes.isEmpty {
                    SettingsSection(title: "Mistakes") {
                        ForEach(summary.mistakes) { mistake in
                            Button { onWhy(mistake) } label: {
                                SettingsRow(label: StrategyText.handLabel(mistake.why)) {
                                    Text(mistakeValue(mistake))
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Explains the correct play")
                        }
                    }
                }
                PrimaryButton(title: "Again", action: onAgain)
                SecondaryButton(title: "Done", action: onDone)
            }
            .padding(FeltSpacing.l)
        }
        .onAppear { showsSaveAlert = saveFailed }
        .alert("Couldn't save this session", isPresented: $showsSaveAlert) {
            Button("OK") {}
        } message: {
            Text("Your results are shown here but won't appear in your progress.")
        }
    }

    private func mistakeValue(_ d: GradedDecision) -> String {
        let chosen: String
        switch d.chosen {
        case .timeout: chosen = "Time's up"
        case .action(let a): chosen = StrategyText.actionName(a)
        }
        return "\(chosen) → \(StrategyText.actionName(d.correctAction))"
    }
}
```

The Strategy feature must not reference Hub, so move the percent formatter to `BJS/Shared/PercentText.swift` as `enum PercentText { static func text(_ fraction: Double?) -> String }`, with the same body as `HubViewModel.percent`, and make `HubViewModel.percent` call it. Keep existing hub tests passing, and add one `PercentText` test to `StrategyTextTests`:

```swift
    @Test("Percent text")
    func percent() {
        #expect(PercentText.text(nil) == "—")
        #expect(PercentText.text(2.0 / 3.0) == "67%")
    }
```

Check `SettingsSection` / `SettingsRow`'s real initialiser signatures in `BJS/Design/Components/SettingsRow.swift` and match them. Don't change those components.

- [ ] **Step 7: Wire `ModuleHost`**

```swift
struct ModuleHost: View {
    let launch: ModuleLaunch
    let onClose: () -> Void
    private let configuration = LaunchConfiguration.current

    var body: some View {
        switch launch.module {
        case .strategy:
            StrategyFlowView(initialSetup: launch.setup.flatMap(StrategySetup.decode),
                             handLimitOverride: configuration.strategyLength, seed: configuration.seed,
                             onClose: onClose)
        case .counting, .shoe, .edge:
            ComingSoonView(title: launch.module.title, message: "Coming in Step \(launch.module.step)",
                           onClose: onClose)
        }
    }
}
```

- [ ] **Step 8: Build and run all tests**

Run: `xcodegen generate && xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -quiet`
Expected: builds with no warnings; all unit tests pass; `FoundationUITests` passes.

- [ ] **Step 9: Commit**

```bash
git add BJS BJSTests
git commit -m "feat(strategy): setup, trainer, WHY sheet and summary screens; wire hub launch"
```

---

### Task 10: Strategy UI test and design check

**Files:**
- Create: `BJSUITests/StrategyUITests.swift`
- Possible fixes in Task 9's Strategy views (layout only, tokens only)

**Interfaces:**
- Consumes: the identifiers listed in Task 9; the launch arguments `-uiTesting -strategyLength 5 -seed 1`.

- [ ] **Step 1: Write the UI test**

```swift
import XCTest

@MainActor
final class StrategyUITests: XCTestCase {

    func testFiveHandSessionReachesSummary() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-strategyLength", "5", "-seed", "1"]
        app.launch()

        let tile = app.buttons["hub.tile.strategy"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()

        let start = app.buttons["strategy.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        for hand in 1...5 {
            let stand = app.buttons["STAND"]
            XCTAssertTrue(stand.waitForExistence(timeout: 5), "hand \(hand): dock")
            stand.tap()
            let next = app.buttons["NEXT"]
            XCTAssertTrue(next.waitForExistence(timeout: 5), "hand \(hand): feedback before the next deal")
            next.tap()
            let deal = app.buttons["strategy.deal"]
            XCTAssertTrue(deal.waitForExistence(timeout: 5), "hand \(hand): outcome")
            deal.tap()
        }

        XCTAssertTrue(app.staticTexts["strategy.summary"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["hub.continue"].waitForExistence(timeout: 5))
    }
}
```

If the summary title isn't found as a `staticText`, query `app.descendants(matching: .any)["strategy.summary"]`.

- [ ] **Step 2: Run it**

Run: `xcodegen generate && xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -quiet -only-testing:BJSUITests`
Expected: `StrategyUITests` and `FoundationUITests` pass. Fix views, not the test's intent, if it fails.

- [ ] **Step 3: Design check (parent spec §7)**

Capture screenshots on **iPhone 16 (iOS 18.4)** and **iPhone SE (3rd gen) (iOS 18.3)** of:
- setup (Weak spots selected, with the note visible);
- trainer awaiting a decision, in Learn with the hint ring and in Speed with the countdown bar;
- the ✓ toast;
- FeedbackCard ✓ and ✕;
- outcome after a split (3 hands);
- the WHY sheet;
- the summary with mistakes.

Approach: a temporary XCUITest (not committed) that drives each state and calls `XCUIScreen.main.screenshot()` into `XCTAttachment`s (`lifetime = .keepAlways`), then `xcrun xcresulttool export attachments --path <xcresult> --output-path <scratch dir>`. To reach a split quickly, try seeds with `-strategyLength 25` and Learn mode until a pair deals, or use the Pairs filter in setup.

Compare each screenshot against parent spec §4 and the frozen components (`FeltCatalogue`):
- only Felt tokens;
- cream primary actions;
- brass only for the hint, the active split hand and the weak-spots note;
- no truncation on the SE;
- tap targets ≥ 44 pt.

Fix layout issues in the Strategy views only. Do not modify frozen components or tokens. If one seems to need a change, stop and report it for Luke's decision.

- [ ] **Step 4: Run everything**

Run: `cd BJSCore && swift test` and the full app test command.
Expected: all green (including `FeltContrast` tests), with no warnings.

- [ ] **Step 5: Commit**

```bash
git add BJSUITests BJS
git commit -m "test(strategy): five-hand UI test; design-check fixes"
```

---

### Task 11: Handoff

**Files:**
- Modify: `docs/superpowers/progress.md`

- [ ] **Step 1: Append a `## Step 3 — Strategy (2026-09-25)` entry** in the style of the Step 2 entry:
- spec, plan, branch and commit range;
- test counts (BJSCore and app, unit and UI);
- what shipped;
- deviations from the plan;
- carry-overs still open:
  - Step 5 ENHC late surrender edge;
  - Step 6 items, now also: history passes `forStats: false`; the heat map should respect Learn exclusion;
  - Step 8 items;
  - the documented A,A vs A ENHC RSA limitation;
- the carry-overs resolved by this step:
  - H14 vs 10 composition;
  - WHY rules context;
  - Continue wiring;
  - the `lastLaunch` decode log;
  - the save-partial orphan risk;
- design-check result;
- "Next: Step 4 (Counting) — brainstorm and plan in a fresh session."

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/progress.md
git commit -m "docs: Step 3 handoff"
```
