# BJS — Blackjack Training App

## What This Is

A native iOS blackjack training app built in Swift/SwiftUI for users who want to seriously improve at blackjack. It covers four skill areas: basic strategy decision training, Hi-Lo card counting fundamentals, casino rule / house-edge analysis, and full card-counting simulation under realistic conditions. This is an educational training product, not a casino app or gambling product.

## Core Value

Users make correct blackjack decisions faster and with more confidence — the app must always give accurate, rule-specific feedback that makes players measurably better.

## Requirements

### Validated

**Basic Strategy Trainer** — Validated in Phase 02: strategy-trainer
- [x] Simulate blackjack hands with configurable casino rules
- [x] Evaluate user decisions against correct basic strategy and provide instant feedback
- [x] Track mistakes and accuracy across sessions

**Core / Architecture** — Validated in Phase 01 (rules engine) and Phase 02 (UI layer)
- [x] Core blackjack rules engine fully independent from UI layer
- [x] Persistent local progress tracking across sessions (SwiftData)
- [x] Offline-first — all core features work without a network connection

### Active

**Basic Strategy Trainer**
- [ ] Simulate blackjack hands with configurable casino rules
- [ ] Evaluate user decisions against correct basic strategy and provide instant feedback
- [ ] Track mistakes and accuracy across sessions
- [ ] Support learn mode, test mode, speed mode, and weak-spot practice mode

**Hi-Lo Practice**
- [ ] Present cards one at a time or in small groups for count drills
- [ ] Accept running count input and measure speed and accuracy
- [ ] Help users memorize and internalize Hi-Lo card values

**Edge Calculator**
- [ ] Accept casino rule inputs (decks, S17/H17, DAS, RSA, surrender, BJ payout, penetration, double restrictions, resplit rules)
- [ ] Calculate house edge estimate from rule set
- [ ] Output game quality rating / playability evaluation

**Full Card Counting Simulator**
- [ ] Simulate a full shoe with running count and true count tracking
- [ ] Configurable rules and deck penetration
- [ ] Realistic pace and pressure simulation
- [ ] End-of-session performance feedback (count accuracy, decision accuracy)

**Core / Architecture**
- [ ] Core blackjack rules engine fully independent from UI layer
- [ ] Persistent local progress tracking across sessions
- [ ] Offline-first — all core features work without a network connection

### Out of Scope

- Multiplayer / social features — niche training tool, no social demand
- Real-money betting or casino integration — not a gambling product
- Live advantage-play assistant / in-casino use tool — not the positioning
- Cross-platform (web, desktop, Android) — iOS first; expand only if product succeeds
- Backend-heavy architecture — offline-first, no server required for core features
- Gimmicks or gamification beyond useful progress tracking — clean, serious product

## Context

- Platform: iPhone (iOS), Swift + SwiftUI + Xcode, no cross-platform frameworks
- Target user: motivated blackjack learners who value accuracy, configurability, and useful feedback over casual entertainment
- The core product differentiator is correctness and configurability — especially the edge calculator and rule-aware strategy engine
- Sessions should be short and repeatable — mobile-first, fast to launch
- Design should feel clean, premium, and slightly analytical (not casino-themed)
- Basic strategy correctness varies by rule set — the strategy engine must handle rule-specific deviations accurately (e.g., composition-dependent plays, S17 vs H17 differences)

## Constraints

- **Tech Stack**: Swift + SwiftUI + Xcode only — no cross-platform, no web, no backend required for v1
- **Platform**: iPhone first — iPad and other platforms deferred
- **Distribution**: App Store (consumer iOS app) — must comply with App Store guidelines; no real-money gambling content
- **Offline**: Core features must work fully offline — no network dependency for training modes
- **Accuracy**: Basic strategy tables and house edge calculations must be mathematically correct — this is the product's credibility

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| iOS/Swift/SwiftUI only | User's explicit direction; fast, native, offline-first | Confirmed |
| Core rules engine separate from UI | Enables testability and future portability | Confirmed — BJSCore package proven in Phase 01 |
| No backend for v1 | Keeps scope tight; offline use is a feature for this audience | Confirmed — SwiftData + UserDefaults only |
| Hi-Lo only (not other count systems) | Simplest standard system; best starting point for learners | — Pending (Phase 03) |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-24 — Phase 02 complete: Strategy Trainer MVP delivered*
