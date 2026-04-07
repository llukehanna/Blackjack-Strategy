# Card Asset Attribution

This directory bundles vector playing-card artwork from two public-domain sources.
All 53 SVG assets in `Cards.xcassets/` are released into the public domain (or
fall back to WTFPL / equivalent) and are redistributable for commercial use.

Verification date: **2026-04-07**

---

## 1. Face cards (52 assets) — `{rank}_of_{suit}.svg`

- **Source repository:** https://github.com/notpeter/Vector-Playing-Cards
- **Original author:** Byron Knoll
- **Original release:** http://byronknoll.blogspot.com/2011/03/vector-playing-cards.html
  (originally hosted on Google Code as `vector-playing-cards`)
- **License:** Public domain, with WTFPL fallback in jurisdictions where public
  domain is not a recognized legal concept.

### License excerpt (from the fork's `README.md`)

> ## License
>
> These images, scripts and subsequent transformational output (e.g. custom
> sized PNGs) are released into the public domain or optionally licensed under
> the WTFPL in juristictions where the public domain is not a recognized legal
> concept. Either way, do as you see fit: relicense, embed in commercial,
> non-commercial or open-source software, etc.
>
> The original source images were released by Byron Knoll into the public
> domain on Google Code as vector-playing-cards.

### File renames applied

The upstream fork uses short filenames (`AC.svg`, `10H.svg`, `KS.svg`, …). They
were renamed to the canonical `{rank}_of_{suit}.svg` form required by
`CardView.assetName`:

| Upstream | Canonical                |
| -------- | ------------------------ |
| `AC.svg` | `ace_of_clubs.svg`       |
| `2H.svg` | `2_of_hearts.svg`        |
| `10D.svg`| `10_of_diamonds.svg`     |
| `JS.svg` | `jack_of_spades.svg`     |
| `QD.svg` | `queen_of_diamonds.svg`  |
| `KC.svg` | `king_of_clubs.svg`      |
| …        | (pattern applies to all) |

Ranks map: `A→ace, 2→2, …, 10→10, J→jack, Q→queen, K→king`.
Suits map: `C→clubs, D→diamonds, H→hearts, S→spades`.

The two `Joker*.svg` files in the upstream fork were not imported (blackjack
does not use jokers).

---

## 2. Card back (1 asset) — `card_back.svg` — **PLACEHOLDER**

> **This asset is a placeholder.** The face-card source (Byron Knoll /
> notpeter fork) does not ship a card-back SVG. Rather than block Phase 7 on
> custom art, we bundle a second CC0 / public-domain back for now and flag it
> for replacement once a project-branded back is produced.

- **Source repository:** https://github.com/saulspatz/SVGCards
- **Original author:** Saul Spatz
- **File used:** `Decks/Vertical2/svgs/redBack.svg` (renamed to `card_back.svg`)
- **License:** Public domain

### License excerpt (from the upstream `README.md`)

> SVGCards
> ========
>
> Public-domain jumbo index playing card decks with two- and four-color suits.

### Replacement plan

A bespoke BJS-branded card back using the `BJSColors.cardBackRed` token
(locked by UI-07-D15) will replace this placeholder in a later plan. The
canonical asset name (`card_back`) will not change — only the contents of
`card_back.imageset/card_back.svg` need to be swapped.

---

## Verification steps performed (2026-04-07)

1. Cloned `https://github.com/notpeter/Vector-Playing-Cards` into `/tmp/bjs-cards` (shallow).
2. Read `README.md` and confirmed the public-domain / WTFPL dual dedication above.
3. Cross-referenced the original Byron Knoll blog post URL.
4. Cloned `https://github.com/saulspatz/SVGCards` into `/tmp/saulspatz` (shallow).
5. Read `README.md` and confirmed the public-domain declaration.
6. Copied 52 face SVGs + 1 back SVG into `Cards.xcassets/` with
   `preserves-vector-representation : true`.

If any upstream license claim is ever successfully challenged, the assets in
this directory must be removed and replaced with verified-clean alternatives.
