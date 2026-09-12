# CLAUDE.md

## Project

iOS remake of **Big Two** (鋤大弟), originally a Palm OS game by Bill (Chan Yiu Por Bill, 2006; earlier version by Woo Kok Tong, 1999). Original site, rules and full changelog: https://bigtwo-palmos.sourceforge.net — treat that page as the spec. Original source is GPL on SourceForge SVN.

**Brief: keep the design and feel of the Palm version.** Not a modern reinterpretation — the flat chrome, the green table, the button layout and the terse wording are the point.

## Stack

SwiftUI, iOS 16+, no dependencies. Files are loose `.swift` sources meant to be dropped into a plain Xcode SwiftUI app target; there is no `.xcodeproj` in the repo yet.

| File | Contents |
| --- | --- |
| `Card.swift` | Rank order 3…A,2 · suit order ♦♣♥♠ · penalty values · sort by rank / suit |
| `Play.swift` | Validation and ranking of 1/2/3/5-card plays, straight ordering, `RuleSet`, `PlayFinder` enumeration |
| `Game.swift` | `BigTwoGame` ObservableObject — dealing, 3♦ lead, passes, tricks, autopass, 10-deal scoring, history log |
| `BotPlayer.swift` | Adam / Carl / Dean heuristics |
| `GameView.swift` | Whole UI: title bar, history strip, table, hand, buttons, score sheet, preferences |

## Visual rules (do not drift from these)

- Table green is `#00cc00` (the lighter green introduced in v2.0.a), with a darker gradient toward the bottom.
- Chrome is a flat light grey bar with a 1px hard black rule beneath. No shadows, no blur, no rounded-card-shadow material.
- Cards: white, 1px black border, 3pt corner radius, rank top-left, suit glyph centre and bottom-right. Red suits use `#cc0000` for the *rank digit* too, as on the Palm.
- Sort buttons are labelled `2` (by rank) and `♠` (by suit), bottom left.
- Play and Pass are hidden when it is not the human's turn (Palm v0.3 behaviour).
- Prompt strings stay terse: "Your Play", "Your Lead", "— new trick —", "WIN!", "DOUBLE!".

## Rules that must not be broken

- Straights: `A2345 < 23456 < 34567 < … < 9TJQK < TJQKA`. `JQKA2` is **not** a straight (disallowed since v1.0).
- Sequence ties broken by the suit of the highest *sequence* card — `3456(7♠)` beats `3456(7♥)`.
- Five-card ranking: straight < flush < full house < four of a kind < straight flush.
- Flush compared on highest card (rank then suit); full house on the triple; four of a kind on the quad.
- Pairs/triples: rank first, then the highest suit present.
- Scoring: a card left in hand costs its rank (3 = 1 … 2 = 13), doubled at 10+ cards left; the winner collects all three penalties.
- 10 deals per game, then the score goes to the high-score list and the cycle restarts.
- Hong Kong rule set (preference toggle): last deal's winner leads, and 23456 becomes the largest straight.

## State of play

Single-player against three bots is complete. It compiles cleanly (Swift 6.2, iOS 16 simulator target, Swift 5 and 6 language modes) and runs in the simulator; a headless run of 20,000 bot-only deals through `BigTwoGame` found no broken invariants (cards conserved, zero-sum deals, correct penalties, no stuck turns). Still no `.xcodeproj` — it was built ad hoc with `swiftc` + a hand-written `Info.plist`.

Open items, roughly in order:

1. Create the Xcode project (see README build steps).
2. Pass-and-play multiplayer. `Seat.isHuman` already drives the loop; it needs the "Next Player's Turn" cover screen that hides the previous player's hand.
3. High-score table — name entry, total rounds, total seconds, max score in one game, score balance (as in v2.2).
4. Landscape layout.
5. Editable player names (v2.0.11).
6. The bot is a fresh greedy heuristic, not a port of the original AI. Worth revisiting against the SVN source.

## Original source

Browsable as raw SVN over HTTP, no `svn` client needed: https://svn.code.sf.net/p/bigtwo-palmos/code/ (r10 = v2.2.9). The shipped AI is `BigTwo/cstate.cpp` — `CState::PalmPlay` and the `Play*` / `LookFor*` / `Strip*` helpers. `BigTwo/Game.cpp` is an older copy with identical AI logic that is not in the makefile. Seat 0 is the human there (`HUMAN` in `TypeDef.h`).

The shipped v2.2.9 Hong Kong code does not match the spec page: it ranks *both* A2345 and 23456 above every other straight (A2345 and 23456 can't beat each other, and a dangling `if` lets any A2345 beat another A2345). We follow the page — only 23456 moves to the top.

## Conventions

- Keep the rules engine (`Card`, `Play`) free of UI and of SwiftUI imports — it should stay unit-testable and portable.
- There are no tests yet. The straight ordering and the five-card comparisons are the parts most worth covering first.
