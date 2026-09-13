# Big Two — iOS

Remake of Big Two v2.2.8 for Palm OS (鋤大弟). SwiftUI, iOS 16+, iPhone, no third-party
dependencies.

## Build

```bash
xcodegen generate                      # only after editing project.yml
open BigTwo.xcodeproj                  # scheme "BigTwo"
swift test --package-path BigTwoKit    # rules engine, no simulator
```

Project layout, conventions and the test workflow are in [CLAUDE.md](CLAUDE.md).

## Rules kept verbatim from the Palm version

- Straights: `A2345 < 23456 < 34567 < … < TJQKA`, `JQKA2` not a straight. Sequence ties
  broken by the suit of the highest sequence card.
- Five-card ranking: straight < flush < full house < four of a kind < straight flush.
- Flush compared on highest card (rank then suit); full house on the triple; four of a
  kind on the quad.
- Scoring: 3 costs 1 … 2 costs 13, doubled at 10+ cards left, winner collects the other three.
- 10 deals per game, then reset.
- Hong Kong rule set: last deal's winner leads, and 23456 becomes the largest straight.
- Autopass, separately toggleable for 5-card turns.
- "I will not play with real money" when every score is zero.

## Palm gestures, mapped to touch

| Palm | iOS |
| --- | --- |
| Tap card | Tap card |
| Press DOWN — select same rank | Long press a card |
| Hold DOWN — select same suit | Double tap a card |
| Sort icons `2` / `♠` | Same two buttons, bottom left |
| Export history to Memo Pad | Menu → Copy history |

## Credits

Big Two for Palm OS © Woo Kok Tong 1999, © Chan Yiu Por Bill 2006, GPL —
https://bigtwo-palmos.sourceforge.net
