# Big Two (鋤大弟) — Development Notes

Conventions follow `~/dev/iChingSwiftUI/CLAUDE.md` (same author, same toolchain) —
only what applies to this app is repeated here.

## 回覆風格（Response style）

- **一律用中文回覆**（繁體），不要用英文長篇說明。
- **條列式為主**，每點一行，避免整段文字。
- **加上 emoji** 標示重點（✅ 完成、⚠️ 注意、🐛 問題、📄 檔案、🧪 測試）。
- **簡短**：只講結果、改了什麼、下一步；細節留在 commit message 裡。

## Project

iOS remake of **Big Two** (鋤大弟), originally a Palm OS game by Bill (Chan Yiu Por Bill,
2006; earlier version by Woo Kok Tong, 1999). Original site, rules and full changelog:
https://bigtwo-palmos.sourceforge.net — treat that page as the spec.

**Brief: keep the design and feel of the Palm version.** Not a modern reinterpretation —
the flat chrome, the green table, the button layout and the terse wording are the point.

## Project Setup

- **XcodeGen** (`project.yml`) — edit `project.yml`, then `xcodegen generate`. **Only run
  it when `project.yml` changed**, and commit `project.yml`, `BigTwo.xcodeproj` and
  `Configurations/BigTwo-Info.plist` together.
  ⚠️ The Info.plist is *generated* from `info.properties` in `project.yml`: a key added
  to the plist by hand is silently dropped on the next generate.
- `BigTwoApp/`, `Resources/` and `BigTwoUITests/` are **synced folders** — adding a file
  there needs no regenerate.
- Bundle id `com.billchan.BigTwo`, team `G5GZ5MPEHS`, iPhone only, portrait, iOS 16+.
  Version and build number live in `Configurations/Version.xcconfig`.
- Swift 6 language mode for the app and `BigTwoKit`. The UI-test target is Swift 5 on
  purpose: `XCUIApplication` is `@MainActor`, and Swift 6 would need isolation on every test.

| Path | Contents |
| --- | --- |
| `BigTwoKit/` | Local package, **no SwiftUI/UIKit**: `Card` (ranks, suits, `SeededGenerator`), `Play` (validation, ranking, `RuleSet`, `PlayFinder`), `Game` (`BigTwoGame` — dealing, 3♦ lead, passes, autopass, 10-deal scoring, history), `BotPlayer`, `Preferences` + `PreferencesStore` |
| `BigTwoApp/` | `BigTwoApp.swift`, `LaunchOptions.swift` (UI-test switches), `Palette.swift` (every color + `Font.palm`), `PalmChrome.swift`, `Views/` |
| `BigTwoUITests/` | `GameUITests`, `ScreenTourUITests`, `UITestSupport` |
| `Resources/` | Asset catalog (AppIcon, AccentColor, LaunchBackground), `PrivacyInfo.xcprivacy` |
| `scripts/` | `extract_screenshots.py`, `make_app_icon.swift` |
| `docs/` | `pr_learnings.md`, `test_runs.md` |
| `screenshots/ios/` | Screen-tour captures — committed |

## Shell & permissions (reduce prompts)

- **Don't prefix Bash commands with `cd <repo>`** — the working directory is already the
  repo root.
- **Prefer the dedicated tools over shell** (`Read`/`Grep`/`Glob` over `cat`/`grep`/`find`).
  Bash is for `xcodebuild`, `xcrun`, `xcodegen`, `swift test`, `git`, scripts.
- **Keep commands un-chained** where possible so each matches an allow rule in
  `.claude/settings.json`. After any permission prompt, add that command there.

## Git, PRs and learnings

- ⚠️ **There is no GitHub remote yet** (`billypchan/BigTwo` does not exist). Until one is
  added, work on a branch and commit; the PR steps below start once it exists.
- **A new feature ends with an open PR against `main`** — standing permission. The PR body
  says what the diff can't: why this approach, what was left out, and **whether it was
  actually built and tested** — never imply a green run that didn't happen.
- **Every PR ends with an entry in `docs/pr_learnings.md`** (newest first), committed with
  the work. A learning that is a *rule* gets promoted into this file too.
- **Commit after green tests; push once per batch** (a push to `main` will cost a CI build
  once Xcode Cloud is set up).

## Visual rules (do not drift from these)

- Table green is `#00cc00` (the lighter green of v2.0.a), with a darker gradient toward the
  bottom.
- Chrome is a flat light grey bar with a 1px hard black rule beneath. No shadows, no blur,
  no rounded-card-shadow material.
  ⚠️ iOS 26 draws a partial-height sheet as translucent glass — the table bleeds through.
  Every sheet over the table takes `.palmSheetBackground()`.
- Cards: white, 1px black border, 3pt corner radius, rank top-left, suit glyph centre and
  bottom-right. Red suits use `#cc0000` for the *rank digit* too, as on the Palm.
- Sort buttons are labelled `2` (by rank) and `♠` (by suit), bottom left.
- Play and Pass are **hidden** when it is not the human's turn (Palm v0.3 behaviour).
- Prompt strings stay terse: "Your Play", "Your Lead", "— new trick —", "*WIN!*", "DOUBLE!".
- **Colors live only in `BigTwoApp/Palette.swift`** — no `Color(red:…)` or bare `.white`
  in a view. `Resources/Assets.xcassets/AccentColor` must hold the same components as
  `Color.feltDeep` (an asset catalog can't read a Swift constant).
- **Touch targets are 44pt even where the Palm look is smaller**: `PalmButtonView` draws
  30pt and hit-tests 44 (`.frame(minHeight: 44)` + `.contentShape`).

## Rules that must not be broken

- Straights: `A2345 < 23456 < 34567 < … < 9TJQK < TJQKA`. `JQKA2` is **not** a straight
  (disallowed since v1.0).
- Sequence ties broken by the suit of the highest *sequence* card — `3456(7♠)` beats
  `3456(7♥)`; A2345's top card is the 5.
- Five-card ranking: straight < flush < full house < four of a kind < straight flush.
- Flush compared on highest card (rank then suit); full house on the triple; four of a
  kind on the quad.
- Pairs/triples: rank first, then the highest suit present.
- Scoring: a card left in hand costs its rank (3 = 1 … 2 = 13), doubled at 10+ cards
  left; the winner collects all three penalties.
- 10 deals per game, then the score goes to the high-score list and the cycle restarts.
- Hong Kong rule set (preference): last deal's winner leads, and 23456 becomes the largest
  straight. **Takes effect from the next deal** — `BigTwoGame.rules` is fixed at each
  deal, since a mid-deal change would re-rank the play on the table.

Every one of these has a test in `BigTwoKit/Tests` — change a rule, change its test.

## Original source

Raw SVN over HTTP, no `svn` client needed: https://svn.code.sf.net/p/bigtwo-palmos/code/
(r10 = v2.2.9). The shipped AI is `BigTwo/cstate.cpp` — `CState::PalmPlay` and the
`Play*` / `LookFor*` / `Strip*` helpers. `BigTwo/Game.cpp` is an older copy with identical
AI logic that is not in the makefile. Seat 0 is the human there (`HUMAN` in `TypeDef.h`).

- The shipped v2.2.9 Hong Kong code does not match the spec page: it ranks *both* A2345
  and 23456 above every other straight (A2345 and 23456 can't beat each other, and a
  dangling `if` lets any A2345 beat another A2345). We follow the page.
- ⚠️ **The original AI is © Woo Kok Tong, GPL.** This remake is fresh code. Porting that
  AI line by line would make the app a derivative of GPL code, and App Store terms are
  widely held to conflict with the GPL. Settle that (reimplement from the behaviour, or
  get permission) *before* porting.

## Tests

### Logic — `swift test` in BigTwoKit (no simulator)

```bash
swift test --package-path BigTwoKit                  # 31 tests, ~10s
swift test --package-path BigTwoKit --filter PlayTests
```

**Pure logic belongs in `BigTwoKit` and its tests in `BigTwoKitTests`** (Swift Testing).
The give-away that a type should move there: it imports only Foundation. Whole-game
tests drive every seat with `BotPlayer` (`humanSeats: [0, 1, 2, 3]`, so nothing runs on a
timer) and check conservation, zero-sum scoring and termination.

### UI — XCUITest on the simulator

```bash
xcodebuild test -project BigTwo.xcodeproj -scheme BigTwo \
  -destination 'platform=iOS Simulator,id=<udid>' > run.log 2>&1; echo $?
```

| Launch argument | Effect (`LaunchOptions`) |
| --- | --- |
| `UITestMode` | 150ms bots; preferences in a throwaway suite, wiped each launch |
| `-seed 2` | Fixed deal: your seat leads with `3d 4c 6h 8h 8s 9c 9s Tc Jd Jc Qc Ad 2c` |
| `-autoplay YES` | The bot plays your seat too — a deal finishes on its own (score sheet) |
| `-keepPreferences YES` | Keep the UI-test preference suite across a relaunch |

- ⚠️ **Never pipe `xcodebuild` into `tail`/`head`** — `$?` becomes the pipe's. Redirect,
  then grep `Executed [0-9]+ test` (it says "1 test", singular — a `tests` pattern misses
  it). A mistyped `-only-testing:` runs zero tests and still prints `** TEST SUCCEEDED **`.
- **Prove the test can fail.** Break what it guards, watch it fail, restore, and log both
  in `docs/test_runs.md`. Evidence from this repo: `sheet.swipeDown()` passed with the
  score sheet made dismissable — it never moves a sheet. Drag from inside the sheet's top
  edge with `coordinate.press(forDuration:thenDragTo:)`.
- ⚠️ **`waitForExistence` is true while a sheet is still sliding in.** Capture after
  `waitUntilSettled(_:)`, or the shot shows a layout bug that isn't there.
- ⚠️ **Overlapping cards must not each own a tap gesture.** Touch slop hands a tap near a
  strip's edge to the neighbour on top — tapping 3♦ selected 4♣. `CardRowView` uses one
  row gesture and picks the card from the x position.
- ⚠️ **A system alert from another app photographs green.** The shared "iPhone 17"
  simulator has had another app's location prompt up over ours. Use a simulator nothing
  else runs on, and keep a tap-with-visible-effect in the tour (it taps 3♦ and asserts
  it is selected) — a tap goes to whatever is really on top.

### After EVERY UI test run — mandatory

0. **Check it ran**: `Executed N test(s)`, not the banner.
1. **Extract**: `python3 scripts/extract_screenshots.py --latest screenshots/ios`
2. **Log** one line to `docs/test_runs.md` — tests, pass/fail count, device.
3. **Look at the images.** Every visual bug on this branch passed its tests first.

Screen-tour names: `ios_screen_NN_<name>` (lead, selected, trick, menu, score).

## Simulator

- This Mac (checked 2026-09-13): **Xcode 26.3**, iOS 26.3 runtime. Use **iPhone 17 Pro Max**
  (`xcrun simctl list devices available` for the UDID — pin by `id=`, never by a `name=`
  that two devices share).
- **Never pass `-derivedDataPath`**, and test in this checkout (not a worktree or `/tmp`
  clone) — both force a full rebuild in a fresh DerivedData tree.

## Code Style

- **2-space indent**, never tabs.
- **Comments say only what the code can't** — the trap, the shipped-data constraint, the
  reason a wrong-looking line is right. One line for a gotcha.
- **Every SwiftUI view type ends in `View`** and lives in a file of the same name, with a
  `#Preview` (works on the iOS 16 target).
- **No force-unwraps / `try!` / `as!` in the app or the kit.** Tests use `#require` /
  `XCTUnwrap`; `var app: XCUIApplication!` in XCUITest is the one allowed IUO.
- **`Text("*WIN!*")` renders italics** — a literal is a `LocalizedStringKey` and parses
  Markdown. Game strings with `*` or `_` use `Text(verbatim:)`.
- ⚠️ **Shipped user data**: `PreferencesStore.key` and `Preferences`' coding keys. Renaming
  either resets everyone's preferences; new preferences decode with `decodeIfPresent`.
- Every tappable thing a test touches has an `accessibilityIdentifier` (`hand_<code>`,
  `button_play`, `score_ok`, `pref_hongKong`, …); cards read as "3 of diamonds" to VoiceOver.

## Release

- App icon: `scripts/make_app_icon.swift` (1024², no alpha — see its header for how to run).
- `PrivacyInfo.xcprivacy` declares UserDefaults (CA92.1) — update it if the app starts
  using another required-reason API. `ITSAppUsesNonExemptEncryption` is `false`.
- Screenshots come from `testScreenTour` (6.9" iPhone 17 Pro Max).

## State of play

Single-player against three bots is complete and runs on the simulator; 31 kit tests and
8 UI tests pass (see `docs/test_runs.md`). Open items, roughly in order:

1. GitHub remote, then CI (Xcode Cloud) and the PR workflow.
2. Save the game in progress — killing the app loses a 10-deal game.
3. High-score table — name entry, total rounds, total seconds, max score in one game,
   score balance (as in v2.2).
4. Pass-and-play multiplayer: `Seat.isHuman` already drives the loop; it needs the
   "Next Player's Turn" cover screen that hides the previous player's hand.
5. Localization — at least zh-Hant (鋤大弟) for the Hong Kong audience.
6. Landscape layout / iPad.
7. Editable player names (v2.0.11).
8. The bot is a fresh greedy heuristic, not the original AI — see "Original source" (GPL)
   before porting.
