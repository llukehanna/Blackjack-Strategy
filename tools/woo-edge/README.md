# Wizard of Odds house-edge data

`BJSCore`'s `EdgeCalculator` reports the house edge from Wizard of Odds' blackjack house edge
calculator (https://wizardofodds.com/games/blackjack/calculator/). House edge by WizardOfOdds.com.

`extract.js` downloads that page, evaluates its inline data script with a stub form, and calls
WoO's own `CalculateResult()` for every rule combination the app supports: 1/2/4/6/8 decks,
S17/H17, DAS, double any two / 9-11 / 10-11, split to 2/3/4 hands, RSA, hit split aces,
peek / no hole card, no / late surrender, and 3:2 / 6:5. That is 5,760 values. It reads the
"Basic strategy with cut card" result for each and writes them, as data only, to
`BJSCore/Sources/BJSCore/Edge/WoOEdgeData.swift`.

Two rules the calculator doesn't offer are handled in `EdgeCalculator`: 2:1 payouts (derived
exactly from the 3:2 and 6:5 values) and early surrender (WoO's rule-variation figures). Early
surrender under no hole card is priced as the no-hole-card table value less 0.63. This slightly
overstates the house edge, because surrendered hands no longer carry the no-hole-card penalty on
doubles and splits. It's a conservative, 8-deck estimate.

Regenerate from the repo root, review the diff, then run `cd BJSCore && swift test`:

    node tools/woo-edge/extract.js

The script executes the page's inline script with a stub DOM. Run it by hand only.
Do not edit the generated file.
