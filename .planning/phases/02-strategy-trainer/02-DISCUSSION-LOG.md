# Phase 2: Strategy Trainer - Discussion Log

**Date:** 2026-03-24
**For:** Human audit reference only. Not consumed by downstream agents.

---

## Areas Discussed

All four areas selected: Card & table style, Feedback UX, Session flow, Rule config & presets.

---

## A — Card & Table Style

**Q: How should cards look?**
Options: Minimal text cards / Stylized card faces / Abstract symbol only
→ **Minimal text cards** — clean rectangle with rank + suit symbol in text

**Q: Should suits be color-coded?**
Options: Color-coded / Single color
→ **Color-coded** — red hearts/diamonds, black clubs/spades

**Q: What does the play area look like?**
Options: Standard vertical layout / Compact single-screen
→ **Standard vertical layout** — dealer top, player middle, action buttons bottom

---

## B — Feedback UX

**Q: What feedback does the user see on a decision?**
Options: Color flash + label / Inline banner stays until tap / Brief explanation on wrong
→ **Color flash + label** — green "Correct ✓" or red "Incorrect — Should: [Action]", ~1 second, auto-advances

**Q: After feedback, does the hand play out?**
Options: Play out the hand / Skip to next hand
→ **Play out the hand** — dealer draws, win/loss/push shown briefly before next hand

**Q: Feedback on every decision or just the first?**
Options: Every decision / First decision only
→ **Every decision** — each hit/stand/double evaluated against correct strategy

---

## C — Session Flow

**Q: How does a session end?**
Options: Open-ended with manual stop / Fixed-length / Both
→ **Open-ended with manual stop** — user taps "End Session"

**Q: Where is Learn vs Test mode chosen?**
Options: Pre-session selection screen / Persistent toggle / Settings
→ **Pre-session selection screen**

**Q: What does the inline mid-session summary show?**
Options: Accuracy % + hand count / Accuracy % + streak / Accuracy % + error count
→ **Other (user specified):** Accuracy % + hand count + error count

**Q: How is the end-of-session summary presented?**
User clarified: wants both an inline mid-session summary AND a thorough end-of-session summary.
Options: Full-screen sheet / Inline screen replacement
→ **Inline screen replacement** — play area animates into summary, same screen, no modal. Shows: hands, accuracy %, errors, streak, mistake log. Actions: [Play Again] [Home].

---

## D — Rule Config & Presets

**Q: Where does the user configure rules?**
Options: Pre-session screen / Persistent app settings / Accessible from both
→ **Accessible from both** — pre-session setup + settings icon during play

**Q: What casino presets ship with the app?**
Options: 3–4 standard US presets / 1–2 presets + custom / Let me specify
→ **1–2 presets + custom** — minimal preset set

**Q: How is custom rule editing presented?**
Options: Sheet/push screen with all rule toggles / Inline expansion
→ **Sheet / push screen** — SwiftUI Form with all toggles and pickers
