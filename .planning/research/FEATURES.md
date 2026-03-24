# Feature Landscape

**Domain:** iOS blackjack training app (strategy, counting, edge analysis)
**Researched:** 2026-03-24
**Confidence:** HIGH -- based on App Store listings, competitor feature sets, community forums, and expert reviews

## Competitive Landscape Summary

The market has three tiers of competitors:

1. **Blackjack Apprenticeship (BJA) Card Counting Pro** -- The incumbent. Focused on Hi-Lo counting, basic strategy, deviations, and bet spread practice. Built by professional advantage players. Strong brand but users complain about missing analytics and limited targeted practice.

2. **Protocol 21** -- The ambitious newcomer. Multiple counting systems, casino noise simulation, speed drills, fatigue detection. Broad feature set but tries to do everything.

3. **Fragmented single-purpose apps** -- Blackjack Trainer 101, Blackjack Strategy Practice, BlackjackIQ Pro, Blackjack All-in-One Trainer. Each does one thing adequately (strategy drills, counting, or edge calculation) but none integrates all four pillars well.

**The gap BJS targets:** No app cleanly integrates all four pillars (basic strategy, Hi-Lo counting, edge calculation, full counting simulation) with rule-aware correctness throughout. Most apps treat strategy and counting as separate concerns. The edge calculator is almost always a web tool (Wizard of Odds, Beating Bonuses), not integrated into training.

---

## Table Stakes

Features users expect. Missing any of these means immediate uninstall.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Basic strategy feedback per hand | Every competitor does this. Users expect instant hit/stand/double/split/surrender feedback. | Medium | Must be correct for the configured rule set, not a generic chart. Rule-specific correctness is the bar. |
| Configurable casino rules | S17/H17, DAS, RSA, surrender, deck count, double restrictions. BJA and every serious app supports this. | Medium | At minimum: decks (1-8), S17/H17, DAS, RSA, late surrender, BJ payout (3:2 vs 6:5), double restrictions (any two, 9-11, 10-11). |
| Running count practice (Hi-Lo) | Core of any counting trainer. Cards shown, user inputs count. | Low | Single card and multi-card group modes. |
| True count conversion | Running count alone is insufficient. Every counting app teaches TC. | Low | TC = RC / decks remaining. Must support configurable deck count. |
| Accuracy tracking per session | Users expect to see their hit rate. All competitors show this. | Low | Percentage correct, streak tracking, per-session summaries. |
| Offline functionality | Training apps that need network = broken product. Every serious competitor works offline. | Low | Already a project constraint. All core features offline. |
| Clean, non-casino-themed UI | Serious trainers (BJA, Protocol 21) have moved away from felt-green casino aesthetics. Users of training apps want analytical, not entertainment. | Medium | Already aligned with project vision. Premium, analytical feel. |
| Speed control for drills | BJA and Protocol 21 both offer adjustable card deal speed. Users expect to control pace. | Low | Range from slow learning pace to fast (sub-1s per card) speed drills. |

## Differentiators

Features that set BJS apart. Not universally expected, but high-value for the target audience.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Integrated house edge calculator | Most apps lack this entirely. Users currently visit Wizard of Odds or Beating Bonuses web calculators separately. Having it in-app, connected to the same rule config used for training, is a genuine differentiator. | High | Must handle: decks, S17/H17, DAS, RSA, surrender, BJ payout, double restrictions, resplit limits. Output: house edge percentage and game quality rating. Consider composition-dependent vs basic strategy edge. |
| Rule-aware strategy engine (not just a lookup table) | Most apps use a single static basic strategy chart. BJS should generate correct strategy for the configured rules. S17 vs H17 changes multiple plays. This is the credibility feature. | High | This is the hardest and most important feature. Strategy deviations between rule sets are subtle but real (e.g., 11 vs A is double with S17, hit with H17 in some configurations). Must be mathematically verified. |
| Weak-spot targeting / adaptive practice | BlackjackIQ Pro does this with "Focus Areas." BJA does not. Most apps deal random hands. Drilling specifically on your worst decisions accelerates learning dramatically. | Medium | Track error rates by hand type (hard totals, soft totals, pairs, specific matchups). Auto-generate practice sets weighted toward weak spots. |
| Full shoe counting simulation with betting | Going beyond isolated drills to simulate a full shoe where the user maintains count, adjusts bets, and makes strategy decisions simultaneously. BJA does this but most others do not. | High | Combine running count, true count, bet sizing, and strategy decisions in one flow. End-of-shoe performance report. This is the "graduation" feature. |
| Performance analytics dashboard | BlackjackIQ Pro offers 70+ statistics. BJA users complain about missing analytics. Deep stats (accuracy by hand type, accuracy by count, improvement over time) are valued by serious learners. | Medium | Charts showing improvement trends. Breakdown by hard/soft/pair. Accuracy at different true counts. Session history. |
| Bet spread practice with EV feedback | Protocol 21 grades betting accuracy. Teaching users when and how much to bet based on true count is the bridge between counting and actually winning. | Medium | Given a true count, user selects bet size. App grades against optimal spread. Shows EV implications. |
| Casino rule presets (named venues) | Users want to configure rules once for "Downtown Vegas 6-deck S17" or "Atlantic City 8-deck." Saves time and reduces configuration errors. | Low | Ship with common presets. Allow user-created presets. Ties directly into edge calculator. |
| Deviation index cards | Protocol 21 has index play flashcards. Knowing when to deviate from basic strategy based on the count (e.g., insurance at TC +3, stand on 16 vs 10 at TC 0+) separates beginners from intermediate counters. | Medium | Hi-Lo index numbers for common deviations (Illustrious 18 and Fab 4 surrender indices). Drill mode for practicing deviations. |

## Anti-Features

Features to explicitly NOT build. Each of these is tempting but wrong for BJS.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Multiple counting systems (KO, Omega II, Zen, Wong Halves, etc.) | Scope explosion. Hi-Lo is the standard learning system and covers 90%+ of counters. Protocol 21 supports many systems but that breadth dilutes depth. BJA deliberately focuses on Hi-Lo only. | Master Hi-Lo completely. Consider other systems only after v1 succeeds and users request them. |
| Casino/gambling aesthetic (green felt, chip animations, dealer avatars) | Signals "entertainment app" not "training tool." Target users are serious learners who want clean data, not casino cosplay. Already an explicit project decision. | Clean, analytical design. Cards should be readable. Data should be prominent. Think "fitness tracker" not "slot machine." |
| Real-money integration or betting with real stakes | App Store policy risk. Wrong positioning. Confuses training with gambling. | Clearly position as educational. No real money flows. |
| Multiplayer or social features | Niche training product. Social features add complexity without value for solo skill-building. Already out of scope. | Solo training only. Leaderboards are optional future consideration at most. |
| AI-powered "coaching" or chat-based explanations | BlackjackIQ Pro markets "AI-powered analysis." This is mostly marketing fluff for rule-based logic. Adding LLM integration adds complexity, cost, and network dependency for minimal value. | Rule-based explanations are better: "You should double 11 vs 6 because the expected value is +X." Clear, deterministic, offline. |
| In-casino live counting assistant | Legal gray area. Wrong product positioning. Would require camera/AR features. | Training app, not a cheating tool. |
| Aggressive ad monetization | Top user complaint across competitors. "Ads every 7 hands" gets 1-star reviews. Destroys the premium positioning. | Paid app or freemium with generous free tier. No interstitial ads during training sessions. |
| Shuffle tracking or ace sequencing | Advanced advantage play techniques that require entirely different training paradigms. Enormous implementation complexity for a tiny audience. | Out of scope for v1 and likely forever. Focus on the four core pillars. |
| Tournament blackjack strategy | Different game with different optimal strategy. Tiny market. | Out of scope. |

## Feature Dependencies

```
Configurable Casino Rules (foundation)
  |
  +---> Basic Strategy Engine (needs rules to generate correct strategy)
  |       |
  |       +---> Basic Strategy Trainer (needs engine for feedback)
  |       |       |
  |       |       +---> Weak-Spot Targeting (needs error tracking from trainer)
  |       |       +---> Speed Mode (needs trainer core)
  |       |
  |       +---> Deviation Index Cards (needs strategy engine + count awareness)
  |
  +---> House Edge Calculator (needs rules as input)
  |
  +---> Hi-Lo Count Practice (independent of strategy, needs deck config)
  |       |
  |       +---> True Count Practice (needs running count + deck estimation)
  |               |
  |               +---> Bet Spread Practice (needs true count)
  |
  +---> Full Shoe Simulation (needs ALL of the above integrated)
          |
          +---> Performance Analytics Dashboard (needs data from all modes)
```

**Key dependency insight:** The casino rules configuration and the basic strategy engine are the foundational layers. Everything else builds on top. Get these right first -- they determine the correctness and credibility of every other feature.

## MVP Recommendation

**Phase 1 -- Foundation (must ship first):**
1. Configurable casino rules engine (the foundation everything depends on)
2. Rule-aware basic strategy engine (the credibility feature)
3. Basic strategy trainer with instant feedback (learn mode + test mode)
4. Session accuracy tracking

**Phase 2 -- Counting fundamentals:**
5. Hi-Lo running count practice (single card + group modes)
6. True count conversion drills
7. Speed mode for both strategy and counting drills

**Phase 3 -- Analysis and intelligence:**
8. House edge calculator
9. Weak-spot targeting / adaptive practice
10. Performance analytics dashboard
11. Casino rule presets

**Phase 4 -- Full simulation:**
12. Full shoe counting simulation with bet spread practice
13. Deviation index training
14. End-of-session comprehensive performance report

**Defer to post-v1:**
- Multiple counting systems: only if user demand validates it
- Bet spread EV analysis: refine after core simulation works
- Casino noise / distraction simulation: nice-to-have, not core

**Rationale:** The dependency chain dictates this order. You cannot build a correct trainer without a correct engine. You cannot build counting simulation without counting drills. The edge calculator is high-value but independent, so it slots into Phase 3 without blocking other work. Full simulation is the capstone that requires all prior pieces.

## Sources

- [Blackjack & Card Counting Pro (BJA) - App Store](https://apps.apple.com/us/app/blackjack-card-counting-pro/id388857410) -- Feature set, user reviews
- [BlackjackIQ Pro - App Store](https://apps.apple.com/us/app/blackjackiq-pro/id6754751115) -- Analytics features, adaptive training
- [Blackjack Trainer: All in One - App Store](https://apps.apple.com/us/app/blackjack-trainer-all-in-one/id1470754366) -- Feature gaps, user complaints about ads
- [Protocol 21 Guide](https://protocol21blackjack.com/ultimate-blackjack-card-counting-app-guide) -- Casino mode, speed drills, distraction features
- [Wizard of Odds House Edge Calculator](https://wizardofodds.com/games/blackjack/calculator/) -- Rule configuration standard for edge calculators
- [Blackjack Review - Training Apps Compared (2025)](https://www.blackjackreview.com/wp/2025/10/15/blackjack-training-apps-compared/) -- Historical software landscape, feature expectations
- [Blackjack Apprenticeship - Training Drills](https://www.blackjackapprenticeship.com/blackjack-training-drills/) -- BJA feature set, Hi-Lo focus rationale
- [BlackjackInfo Community - Training Apps Thread](https://www.blackjackinfo.com/community/threads/training-apps.56364/) -- User frustrations, what serious players want
