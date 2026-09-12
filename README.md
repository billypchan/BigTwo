# Big Two — iOS

Remake of Big Two v2.2.8 for Palm OS. SwiftUI, iOS 16+, no dependencies.

## Build

1. Xcode → New Project → iOS App → SwiftUI, product name `BigTwo`.
2. Delete the generated `ContentView.swift` and `*App.swift`.
3. Drag in all `.swift` files from this folder.
4. Run.

## Files

| File | What's in it |
| --- | --- |
| `Card.swift` | Rank order 3…A,2 · suit order ♦♣♥♠ · penalty values · sort by rank / by suit |
| `Play.swift` | Validation and ranking of 1/2/3/5-card plays, straight ordering, `RuleSet`, play enumeration |
| `Game.swift` | Dealing, 3♦ lead, passes, tricks, autopass, 10-deal scoring with doubling, history log |
| `BotPlayer.swift` | Adam / Carl / Dean — cheapest legal play, holds bombs back, pushes when someone is near out |
| `GameView.swift` | Screen: title bar, history strip, green table, hand, sort/clear/pass/play, score sheet, preferences |

## Rules kept verbatim from the Palm version

- Straights: `A2345 < 23456 < 34567 < … < TJQKA`, `JQKA2` not a straight. Sequence ties broken by the suit of the highest sequence card.
- Five-card ranking: straight < flush < full house < four of a kind < straight flush.
- Flush compared on highest card (rank then suit); full house on the triple; four of a kind on the quad.
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

## Not carried over yet

- Multiplayer (pass-and-play, and the IR/Bluetooth games). Pass-and-play is the easy one: `Seat.isHuman` already drives it, it needs the "Next Player's Turn" cover screen.
- High score table with rounds / seconds / max score.
- Landscape layout.
- Player name editing.
