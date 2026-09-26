# Step 3 — Strategy — Design

**Date:** 2026-09-25
**Status:** Approved in brainstorming; pending written-spec review
**Parent spec:** `2026-09-23-bjs-rebuild-design.md` (§5 Strategy and Hub, §6 data, §7 testing, §8 Step 3)

Step 3 builds the Strategy module: the setup screen, the trainer in four modes, the WHY sheet, the summary, persistence, and the hub's Continue button. This document records only what the parent spec leaves open or amends, plus the carry-overs from `progress.md`. Everything else follows the parent spec as written.

The Felt design system is frozen. This step adds new components built from existing tokens, and it changes no existing token or component.

## 1. Decisions and amendments

| Topic | Decision | Why |
|---|---|---|
| Feedback cadence | A **wrong** decision always shows the `FeedbackCard`. So does any decision that **ends the player's turn**. A correct decision that leaves play going (a hit that doesn't finish the hand, a split, a stand on an earlier split hand) shows a brief ✓ toast and play continues. | Every mistake gets full feedback, and multi-decision hands don't need a tap per correct decision. The parent spec's "feedback before outcome" still holds, because the turn-ending decision always shows the card. |
| After a wrong decision | The hand continues with the **user's** action. | The outcome reflects what they chose. The card already names the correct play. |
| Outcome reveal | NEXT on the turn-ending feedback flips the hole card, shows the dealer's draws and an outcome line. The next hand deals only when the user taps **DEAL**. | Luke's choice: control over pace. |
| Speed timeout | Recorded as `timeout` (wrong). The card says "Time's up: the play was X". NEXT abandons the hand (no reveal, no outcome) and deals the next hand. The timer is paused while feedback shows. | The app never plays on the user's behalf. |
| Learn mode in stats | Learn sessions are saved and appear in history. Their decisions are **excluded** from accuracy, the streak and weak-spot weights. | Hinted answers would inflate every stat. |
| Early surrender, hard 14 vs 10 | Grading applies WoO's composition note exactly (§3). | Maths correctness. Luke's choice over "accept either". |
| Reaction time | Recorded for every decision in every mode. The summary shows the average only in Speed mode (parent spec). | Step 6 can use it later at no extra cost. |

## 2. Structure and navigation

- **`Features/Strategy/`:**
  - `StrategySetup`: mode, length, filter; `Codable`; stored in `lastLaunch.setup`.
  - `StrategySetupView`
  - `StrategyTrainerView` + `StrategyTrainerViewModel`
  - `WhySheet`
  - `StrategySummaryView`
  - `StrategyFlowView`: hosts setup → trainer → summary inside one full-screen cover.
- **`StrategyMode`:** `learn`, `test`, `speed`, `weakSpots`. The raw value is stored as `Session.mode`.
- **`StrategyLength`:** `hands(25)`, `hands(50)`, `hands(100)`, `endless`.
- **Launch routing without cross-feature imports:**
  - `AppRouter` (Shared) gains `launch: ModuleLaunch?`.
    - `ModuleLaunch { module: AppModule; setup: Data? }` is `Identifiable`, with a fresh id per launch.
    - `AppModule` (strategy, counting, shoe, edge) moves to Shared, taking over from `HubModule`. The title, subtitle and step stay with it.
  - The hub's tiles and Continue set `router.launch`.
  - `RootTabView` (App) owns the `.fullScreenCover`. It maps strategy to `StrategyFlowView` and the other modules to `ComingSoonView`.
  - The hub no longer presents anything itself.
- **Continue:**
  - Starting a session writes `PreferencesStore.lastLaunch` (module `.strategy`, mode raw value, encoded setup).
  - Continue sets `router.launch` with that setup, and `StrategyFlowView` goes straight to the trainer.
  - If the setup fails to decode, it shows the setup screen and logs the failure.
  - `PreferencesStore` logs a `lastLaunch` decode failure at init (carry-over).
- **New components** (`Design/Components/`, existing tokens only, each added to `FeltCatalogue`):
  - `FlipCard`: wraps `PlayingCard`. It flips over `FeltMotion.flip`, or cross-fades under Reduce Motion (`FeltMotion.revealStyle`).
  - `FeltToast`: a small ✓ pill on `surfaceInset`, with the glyph in `correct`. It auto-dismisses after about 0.8 s and is announced to VoiceOver.
  - `CountdownBar`: a thin bar that drains from `cream` to `incorrect` in the last second. Under Reduce Motion it shows discrete steps.
  - `SplitHandsView`: lays out 1–4 player hands (`HandView`) and scales the card width to fit. The active hand gets a `brass` underline, the "highlight" role `brass` already has.

## 3. BJSCore changes (TDD)

1. **Composition note in grading.**
   - `StrategyTable` gains an early-surrender composition exception, built by `WoOChartDecoder` when `surrenderRule == .early`, `peekRule == .americanPeek` and the deck count is 1 or 2.
   - `action(for:dealerUpcard:legal:)` applies it to a two-card hard 14 vs a ten-value upcard. Source: https://wizardofodds.com/games/blackjack/surrender/ ("Do not surrender 10 Vs. 4+10 or 5+9 in single deck"; "Do not surrender 10 Vs. 4+10 in double deck").
     - 1 deck: surrender 8+6 only. 10+4 and 9+5 hit.
     - 2 decks: surrender 9+5 and 8+6. 10+4 hits.
     - 4+ decks: every hard 14 surrenders (unchanged).
     - 7,7 is graded on its pair row, which surrenders.
   - The non-surrender alternative is the existing late-chart action (hit).
   - `WoOChartTests` stay green. The chart grids (`hardTotals` and so on) keep showing the total-level cell.
2. **`WhyContext(spot:chosen:correct:rules:)`.**
   - It builds the context from the **graded row**: `.pair` only when the hand is a pair and split is legal; otherwise soft or hard by the hand.
   - `userAction` becomes `Action?`, where `nil` means Speed timeout.
   - New fields:
     - `preferredIllegal: Action?`: the table's first preference when it wasn't legal (for example double on a 3-card soft 18);
     - `surrenderContext: SurrenderContext?` (`late`, `early`, `noHoleCard`);
     - `compositionNote: Bool`.
3. **`WhyExplanation` templates.**
   - When `preferredIllegal` is set, the text leads with "Doubling would be best, but it isn't allowed here, so …".
   - `(hard, surrender)` and `(pair, surrender)` under early or no-hole-card surrender explain surrendering before the dealer checks for blackjack (for example hard 5 vs A).
   - The composition note explains the 14 vs 10 exception.
   - Existing bounds hold: 30 to 399 characters, total over every combination.
4. **Known limitation, documented rather than fixed:** under no hole card with RSA, split A,A vs A falls back to stand where resplitting is better. It only arises after a deviation.

## 4. Trainer flow

`StrategyTrainerViewModel` (`@Observable`, `@MainActor`) is a phase machine over `RoundEngine`. It takes an injected RNG and clock, so tests are deterministic.

1. **Deal:**
   - `HandGenerator.sampleCell(filter:weights:)`, with weights only in Weak spots;
   - then `stackedShoe(for:deckCount:peekRule:)`;
   - then `RoundEngine(rules: snapshot)`.
2. **`awaitingDecision(spot)`:**
   - the dock shows legal actions, with the hint (`table.action(for: spot)`) in Learn mode only;
   - the decision start time is stamped;
   - Speed mode starts the countdown.
3. **Decide `a`:**
   - grade `isCorrect = a == table.action(for: spot)`;
   - record a `DecisionDraft` (`TrainingCell(spot:)`, chosen, correct, response ms, time);
   - apply `a` to the engine;
   - haptic (success or error) when enabled;
   - if the decision is wrong, or the engine left `playerTurn`, go to `feedback(result)`;
   - otherwise show the ✓ toast and go to `awaitingDecision` with the new spot.
4. **`feedback` → NEXT:**
   - if the engine is still in `playerTurn`, go to `awaitingDecision`;
   - if the hand was abandoned by a timeout, deal the next hand, or go to the summary;
   - otherwise go to `outcome`.
5. **`outcome`:**
   - the view flips the hole card and shows the dealer's drawn cards. The engine settled earlier; the ViewModel keeps the dealer's hole card and draws hidden until this phase;
   - the outcome line comes from each hand's `HandOutcome` and `net` (for example "Win +1", "Bust −2", or one entry per split hand);
   - DEAL deals the next hand, or goes to the summary when the length is reached.
6. **Timeout** (`timeoutElapsed()`, called by the view's timer task):
   - records `.timeout` as wrong, with response ms = the timer length;
   - goes to `feedback`, marked as abandoning the hand.

The header shows hand n / N (or n for Endless), correct/total so far, and the current in-session streak. Endless shows an END button.

**Weak spots:**
- Weights come from `WeakSpotWeights.compute` over stats-eligible strategy and shoe decisions (§5).
- When the result is `nil` (under 50 decisions), the setup screen shows "Not enough history yet: hands are dealt evenly", and dealing is uniform.
- The hand filter applies in every mode.

**WHY sheet:**
- Built from the decision's `WhyContext` (rules snapshot, graded row).
- Shows a title ("Hard 16 vs 10"), your play vs the correct play ("Time's up" for a timeout), `WhyExplanation.explain`, and `RulesSummary.text(for: rules)`.
- Opened from the `FeedbackCard` WHY button and from summary mistake rows. `.presentationDetents([.medium, .large])`.

## 5. Sessions and persistence

- **Session start:** `id = UUID()`, `startedAt`, rules snapshot, and `lastLaunch` is written.
- **End:**
  - Fixed length: reaching N hands (a hand counts once it is dealt and resolved or abandoned) goes to the summary.
  - Endless: END goes to the summary, or closes when nothing has been graded.
- **Leaving mid-session (×):**
  - With at least 1 graded decision, a confirmation dialog offers **Save partial** (save, then summary) or **Discard** (close).
  - With none, it closes straight away.
- **Save once:** the ViewModel's `hasSaved` guard means a session id reaches `SessionStore.save` at most once. The upsert/orphan risk can't occur, and a test covers it.
- **Save failure:** a non-blocking alert ("Couldn't save this session"). The summary is still shown.
- **Learn exclusion:**
  - `SessionStore.sessionSamples`, `decisionSamples` and `countSamples` gain `forStats: Bool = true`. When it is true, they drop sessions whose `mode == "learn"`.
  - The hub and Weak spots use the default. Step 6 history passes `false`.
  - No schema change.
- **Summary:**
  - accuracy, mistakes, best streak, hands played, and average decision time (Speed only);
  - the mistakes list (hand label, your play → correct play) opens each WHY sheet, using contexts kept in memory;
  - **Again** starts a new session with the same setup; **Done** closes.
- **UI-test hooks** (`LaunchConfiguration`, honoured only with `-uiTesting`): `-strategyLength N` overrides the length, and `-seed N` seeds the trainer RNG.

## 6. Testing

- **BJSCore (Swift Testing, TDD):**
  - composition-note grading for 1D, 2D and 6D (every hard 14 composition vs 10, plus 7,7 and vs A unaffected, and late surrender unaffected);
  - `WhyContext(spot:…)` row selection (a pair with split illegal → hard; 3-card soft 18 vs 6 → `preferredIllegal == .double`);
  - the new template branches and length bounds.
  - Existing 211 tests stay green.
- **App (Swift Testing), with stacked shoes and a seeded RNG:**
  - phase sequences per mode;
  - Learn hint present only in Learn;
  - a correct hit shows a toast and stays in `awaitingDecision`;
  - a wrong hit shows feedback;
  - split flow across hands;
  - Speed timeout abandons the hand;
  - fixed length → summary;
  - Endless END;
  - Save partial / Discard;
  - save-once guard;
  - save failure still shows the summary;
  - `lastLaunch` round trip and Continue fallback;
  - `SessionStore` Learn exclusion;
  - Weak spots uniform-fallback flag.
- **Required regression test:** every turn-ending decision, including STAND, puts the ViewModel in `feedback` before any next deal. It is run across all modes and several seeds.
- **UI test (XCTest):** launch (`-uiTesting -strategyLength 5 -seed 1`) → hub → Strategy tile → Test mode → Start → tap STAND, NEXT, DEAL five times → the summary is visible.
- **Design check:** iPhone 16 and iPhone SE screenshots of setup, trainer (awaiting, toast, feedback, outcome, split), WHY sheet and summary, compared against parent spec §4. The contrast test stays green, and `FeltCatalogue` shows the new components.

## 7. Out of scope

- The Progress tab (Step 6) and Shoe Sim (Step 7), apart from the `forStats` query parameter.
- Deviation indices, and composition-dependent strategy beyond the one WoO note in §3.
- Changes to any frozen token or component.
