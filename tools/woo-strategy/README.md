# Wizard of Odds strategy data

`BJSCore` grades every strategy decision against Wizard of Odds' published basic strategy
(https://wizardofodds.com/games/blackjack/strategy/calculator/). Strategy by WizardOfOdds.com.

`extract.js` downloads that page and writes two generated files:

- `BJSCore/Sources/BJSCore/Strategy/WoOStrategyData.swift`: WoO's six chart tables
  (1 / 2 / 4+ decks × S17 / H17), taken as data only.
- `BJSCore/Tests/BJSCoreTests/StrategyTests/WoORenderedCharts.swift`: the charts WoO's own
  page renders for 48 rule combinations. `WoOChartTests` requires our decoded charts to
  match them cell for cell.

Regenerate from the repo root, review the diff, then run `cd BJSCore && swift test`:

    node tools/woo-strategy/extract.js

The script executes the page's inline data script with a stub DOM. Run it by hand only.
Do not edit the generated files.
