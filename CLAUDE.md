# BJS — Blackjack Training App

Native iPhone blackjack **trainer** (Swift 6.2 / SwiftUI / iOS 18+). Users get measurably better at basic strategy and Hi-Lo counting through accurate, rule-specific feedback. Educational only: no wagering, no real money. Visually it looks like a casino table (felt green, cream cards); behaviourally it's a serious training tool.

**Source of truth:** `docs/superpowers/specs/2026-09-23-bjs-rebuild-design.md` (the rebuild spec). Read it before planning any work.
**Progress log:** `docs/superpowers/progress.md`. Read the latest entry before starting a step; append a handoff entry when finishing one.
**Plans:** `docs/superpowers/plans/`

## Workflow

- Use superpowers skills: brainstorming → writing-plans → subagent-driven-development (or executing-plans) → verification-before-completion. TDD for all logic.
- Do **not** use GSD (`/gsd:*`); it was retired on 2026-09-23.
- One plan per build step (spec §8). Finish and verify a step before starting the next.
- Manage context: a fresh subagent per task; the main session coordinates. Write the step handoff to `progress.md` and start the next step in a fresh session.

## Architecture rules (spec §3)

1. All game logic lives in `BJSCore` (Swift package, no SwiftUI/SwiftData imports): dealing, rounds, strategy, counting, drills, explanations, weighting, statistics.
2. ViewModels are thin `@Observable` adapters: call the engine, map for display, sequence animations, persist.
3. One app-wide active rule set (`ActiveRulesStore`, `@AppStorage` JSON). Sessions snapshot their rules.
4. Feature folders (`BJS/Features/*`) never import each other; shared code lives in `Design/`, `Shared/`, `Persistence/` or `BJSCore`.
5. Randomness is injectable: take `inout some RandomNumberGenerator`; tests use `SeededRandomNumberGenerator`.
6. XcodeGen owns the project: edit `project.yml`, never the `.xcodeproj` (gitignored).

## Design system freeze (spec §4)

The Felt design system is the only design system. It is **frozen at the end of Step 2**. Later steps may add new components built from existing tokens, but must not restyle or re-tune existing tokens or components. A change to a frozen token needs an explicit decision from Luke in its own change, never inside a feature step. There are no "redesign" steps.

- **Frozen on 2026-09-25** after Luke's sign-off (review page: https://claude.ai/artifact/44U1bKzLPNxgDKiXLeQexN). The DEBUG `FeltCatalogue` (Settings → Debug, or launch with `-showCatalogue`) is the reference to check against.
- **Pre-approved exception:** accessibility-only fixes to frozen components (Dynamic Type up to AX3, VoiceOver, Reduce Motion) are allowed in Step 8, as long as the default-text-size appearance does not change.
- iOS 26 draws the tab bar as system Liquid Glass. This is accepted; don't opt out of it.
- The app is portrait-only on iPhone.

## Commands

```bash
# Engine tests (fast, no simulator)
cd BJSCore && swift test

# App: regenerate project, build, run unit tests
xcodegen generate
xcodebuild test -project BJS.xcodeproj -scheme BJS -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -quiet
```

## Conventions

- Swift Testing (`@Test`, `#expect`) for unit tests; XCTest only for UI tests.
- Commit after each task; conventional prefixes (`feat`, `fix`, `refactor`, `test`, `docs`, `chore`) with a scope (`core`, `app`, or a feature name).
- Maths correctness is the product's credibility: strategy and edge changes need tests against Wizard of Odds reference values.
