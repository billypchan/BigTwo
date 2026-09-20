# Big Two (鋤大弟) — Development Notes

Conventions follow `~/dev/iChingSwiftUI/CLAUDE.md` (same author, same toolchain) —
only what applies to this app is repeated here.

## 回覆風格（Response style）

- **一律用中文回覆**（繁體），不要用英文長篇說明。
- **條列式為主**，每點一行，避免整段文字。
- **加上 emoji** 標示重點（✅ 完成、⚠️ 注意、🐛 問題、📄 檔案、🧪 測試）。
- **簡短**：只講結果、改了什麼、下一步；細節留在 commit message 裡。

## Project

iOS remake of **Big Two** (鋤大弟), originally a Palm OS game by Bill Chan, 2006; earlier version by Woo Kok Tong, 1999. Original site, rules and full changelog:
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
- Bundle id `com.billchan.BigTwo`, team `G5GZ5MPEHS`, iPhone only, portrait, **iOS 17+**
  (SharedKit). Kit stays iOS 15. Xcode Cloud / current SDKs accept 15.0–27.0.
  Deployment target, team and Swift version live in `Configurations/Shared.xcconfig`;
  version and build number in `Configurations/Version.xcconfig` (which includes Shared).
- Swift 6 language mode for the app and `BigTwoKit`. The UI-test target is Swift 5 on
  purpose: `XCUIApplication` is `@MainActor`, and Swift 6 would need isolation on every test.

| Path | Contents |
| --- | --- |
| `BigTwoKit/` | Local package, **no SwiftUI/UIKit**: `Card` (ranks, suits, `SeededGenerator`), `Play` (validation, ranking, `RuleSet`, `PlayFinder`), `Game` (`BigTwoGame` — dealing, 3♦ lead, passes, autopass, 10-deal scoring, history), `BotPlayer` (Palm-style bots, `BotContext`), `Preferences` + `PreferencesStore` |
| `BigTwoApp/` | `BigTwoApp.swift`, `LaunchOptions.swift` (UI-test switches), `L10n.swift` (UI copy), `Palette.swift` (every color + `Font.palm`), `PalmMetrics.swift` (Palm units, `PalmPressStyle`), `Views/` |
| `BigTwoUITests/` | `GameUITests`, `ScreenTourUITests`, `UITestSupport` |
| `Resources/` | Asset catalog (AppIcon, AccentColor, LaunchBackground), `PrivacyInfo.xcprivacy`, `*.lproj` (en, zh-Hant, zh-Hans, id, fil, ms, vi) |
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

- Public repo **github.com/billypchan/BigTwo**, MIT (`LICENSE`). Anything committed is
  published — no keys, no `.p8`, no personal data.
- **A new feature ends with an open PR against `main`** — standing permission. The PR body
  says what the diff can't: why this approach, what was left out, and **whether it was
  actually built and tested** — never imply a green run that didn't happen.
- **Every PR ends with an entry in `docs/pr_learnings.md`** (newest first), committed with
  the work. A learning that is a *rule* gets promoted into this file too.
- **Commit after green tests; push once per batch** — every push to `main` costs an
  Xcode Cloud build (workflow "Default", GitHub check run `BigTwo | Default | Archive - iOS`).

## Visual rules (do not drift from these)

The reference is the Palm itself: the SourceForge screenshots
(https://sourceforge.net/projects/bigtwo-palmos/ and the images on
https://bigtwo-palmos.sourceforge.net — `Start.gif`, `portrait.gif`, `menu.gif`, `prefs.gif`,
`GameHist.gif`). When in doubt, match them.

- **The game is one square** — the Palm's 320×320 screen. `GameView` sizes it to
  `min(width, …)` and lays everything out in Palm units (`\.palmUnit` = side / 320), so it
  scales as a whole. Around it: the dark `bezel`, status bar hidden.
- **Below the square, the card tracker** (♦♣♥♠ × 3…2, played cards white) — where the
  Palm's portrait screen put it, in the input area.
- Title: a navy "Big Two" tab (green text) over a navy rule; **tapping the title opens the
  menu**, as on the Palm. "Deal n/10" at the right where the Palm showed its version.
- **One row per player, in play order from you** (Bill, Carl, Dean, Adam): grey name button
  (inverted on that player's turn), their last move this deal — the cards, or "PASS" — and
  `left: N`.
- Lead/Play and Pass are white pills with a black border, bottom-right of the rows,
  **hidden** when it is not your turn (Palm v0.3). Beside them: an empty box (clear the
  selection) and **one sort icon** that shows the order a tap switches to (`♠` / `2`).
- Your hand runs along the bottom edge. Cards: white, 1px black border, rank top-left with
  the suit under it (a strip still reads); red suits colour the rank too (`#cc0000`).
  **Selected cards are inverted** (black face), not raised.
- Menus and dialogs are **Palm forms inside the square** (`PalmMenuView`, `PalmDialogView`:
  navy title bar, white body, pill buttons) — never iOS sheets. They are modal: a clear
  layer swallows taps outside them. Preferences keep the Palm wording ("Auto pass",
  "Enable autopass for 5-card turn", "Use Hong Kong Rule Set", "Game speed: Slow | Medium |
  Fast", "Sort cards by: Rank | Suit", "Bots: Classic | Strong").
- Table green is a **flat** `#00cc00`, as on the Palm screen. No shadows (the menu's hard
  2px offset is the one exception — it is the Palm's), no blur, no glass.
- Buttons use `PalmPressStyle`: SwiftUI's plain style fades a disabled button to a washed-out
  green; Palm greys the text and keeps the white pill.
- Prompt strings stay terse: "Your Play", "Your Lead", "*WIN!*", "DOUBLE!", "PASS".
  Visible copy goes through `L10n.string`; keys are the English UI text.
  `PalmButtonView.title` is `String`, so a `Text("literal")` lookup never runs there.
  Identifiers stay English (`pref_bots_Classic`). UI tests launch with
  `-AppleLanguages (en)`. zh-Hant home/title name is 鋤大弟 (U+92E4), not 鍥.
  Every locale table must have the same keys, **and every key a view asks for must be
  in them** — `L10n.string` falls back to the key, so a typo ships English to all seven
  languages and no test fails (`"I will not play with real money."` with a trailing
  period did exactly that in the About dialog; the four About rows had no entry at all).
  ⚠️ A fixed-width pill (`PalmButtonView.width`) does not grow: check a long
  translation in the screenshot, or shorten it (vi "Source" is "Nguồn", not "Mã nguồn").
  **Screenshot another language**: `xcodebuild test … -only-testing:BigTwoUITests/ScreenTourUITests/testScreenTour -testLanguage vi`
  and extract into a scratch dir. `XCUIApplication.uiTestLanguage` reads the runner's
  own `-AppleLanguages` argument, so the label assertions stand aside; the run stays
  English-pinned on any simulator otherwise. `TEST_RUNNER_<VAR>=…` on the xcodebuild
  command line does **not** reach the runner — that needs a test plan.
- **Colors live only in `BigTwoApp/Palette.swift`** — no `Color(red:…)` or bare `.white`
  in a view. `Resources/Assets.xcassets/AccentColor` must hold the same components as
  `Color.feltDeep` (an asset catalog can't read a Swift constant).
- **Touch targets are 44pt even where the Palm look is smaller** (`PalmMetrics.minTouch`):
  pills draw 20 Palm units and hit-test 44pt. The one exception is the title tab — the
  title bar is only 24 units tall.

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
- ⚠️ **Never copy or translate code from the SVN source.** It is GPL (© Woo Kok Tong 1999,
  Bill 2006); this remake is MIT and on the App Store, and a translated function would
  make it a derivative. Describe the behaviour, then write it fresh — that is how
  `BotPlayer.swift` was made.
- The bots keep the Palm habits on purpose, including the two cheats: they **see every
  hand** (`BotContext.hands`) and a bot **lets a fellow bot's K/A/2 single stand**. Both
  are in `BotPlayerTests`; turning either off changes the game's difficulty.
- **Strong bots** (`StrongBot`, default on, Preferences → Bots: Classic | Strong) do
  **not** peek (own hand + `left: N` only) and **do** fight fellow bots. Classic still
  peeks and lets a fellow bot's K/A/2 stand. `oneStrongBotOutscoresThreeGreedyBots`
  keeps one Strong seat ahead of greedy. `Game.botChoice` picks Strong or Classic from
  `preferences.strongBots`.

## Tests

### Logic — `swift test` in BigTwoKit (no simulator)

```bash
swift test --package-path BigTwoKit                  # 46 tests, ~30s
swift test --package-path BigTwoKit --filter PlayTests
```

**Pure logic belongs in `BigTwoKit` and its tests in `BigTwoKitTests`** (Swift Testing).
The give-away that a type should move there: it imports only Foundation. Whole-game
tests drive every seat with `BotPlayer` (`humanSeats: [0, 1, 2, 3]`, so nothing runs on a
timer) and check conservation, zero-sum scoring and termination.
`BotPlayerTests` pins each bot habit to a hand, and `palmBotsOutscoreTheGreedyBot` keeps
the app's first bot (`GreedyBot`, test target only) as a yardstick: over 8 seeded games
the greedy seat finished at −719. A bot change that makes that number go up is a
regression in strength, whatever the intent.

### UI — XCUITest on the simulator

```bash
xcodebuild test -project BigTwo.xcodeproj -scheme BigTwo \
  -destination 'platform=iOS Simulator,id=<udid>' > run.log 2>&1; echo $?
```

| Launch argument | Effect (`LaunchOptions`) |
| --- | --- |
| `UITestMode` | 150ms bots; preferences in a throwaway suite, wiped each launch |
| `-AppleLanguages (en)` | Set by `XCUIApplication.bigTwo` so prompt/button labels stay English |
| `-seed 2` | Fixed deal: your seat leads with `3d 4c 6h 8h 8s 9c 9s Tc Jd Jc Qc Ad 2c` |
| `-autoplay YES` | The bot plays your seat too — a deal finishes on its own (score sheet) |
| `-dealsPerGame 1` | One-deal game, so autoplay opens **Final Score** / New Game |
| `-keepPreferences YES` | Keep the UI-test preference suite across a relaunch |

- ⚠️ **Always run the edited UI test** after changing a view or its XCUITest. Do not
  skip because the change looks small.
- ⚠️ **Do not tap `pref_source`.** It opens Safari; the test cannot come back.
- ⚠️ **Never pipe `xcodebuild` into `tail`/`head`** — `$?` becomes the pipe's. Redirect,
  then grep `Executed [0-9]+ test` (it says "1 test", singular — a `tests` pattern misses
  it). A mistyped `-only-testing:` runs zero tests and still prints `** TEST SUCCEEDED **`.
- **Prove the test can fail.** Break what it guards, watch it fail, restore, and log both
  in `docs/test_runs.md`. Evidence from this repo: `sheet.swipeDown()` passed with the
  score sheet made dismissable — it never moves a sheet. Drag from inside the sheet's top
  edge with `coordinate.press(forDuration:thenDragTo:)`.
- ⚠️ **Wait for the state a tap causes; never read it on the next line.** On a loaded
  Mac the app lags the synthesized taps: `isSelected` read right after `tap()` was false,
  and a Play tapped before the second card's selection landed led a single. Use
  `waitForCount(app.selectedHandCards, n)` / `waitFor(_:label:)` first.
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
   (keeps the old PNG if the new shot differs only in the status-bar clock;
   `--force` overwrites). Freeze the clock first with
   `scripts/freeze_status_bar.sh <udid>` so new shots show 9:41.
2. **Log** one line to `docs/test_runs.md` — tests, pass/fail count, device.
3. **Look at the images.** Every visual bug on this branch passed its tests first.

Screen-tour names: `ios_screen_NN_<name>` (lead, selected, trick, menu, preferences, names, about, score, final_score).

## Simulator

- ⚠️ **Checked 2026-09-13: the Data volume is 99 % full (≈3 GB free).** Time Machine and
  cache deletion push the load average to 50–75 and every UI test slows down (launch
  took 18 s). Free space before trusting a timing failure.
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
  `button_play`, `score_ok`, `pref_hongKong`, `about_sharedkit`, …); cards read as "3 of diamonds" to VoiceOver.

## Release

- **Run `/release`** to ship a version: the flow (version check, release notes,
  metadata, screenshots, build, submit, tag, bump) is the global `release` skill,
  `~/.claude/skills/release/SKILL.md`, and this app's values — bundle id, scheme, the
  kit-test preflight, the store-text rules below — are in **`.claude/release.json`**.
  App Store Connect from the command line:
  `swift ~/.claude/skills/release/scripts/asc.swift builds --version 1.1` (run from
  the repo root; auth is `ASC_KEY_ID` / `ASC_ISSUER_ID` + the `.p8`).
- App icon: `scripts/make_app_icon.swift` (1024², no alpha — see its header for how to run).
- `PrivacyInfo.xcprivacy` declares UserDefaults (CA92.1) — update it if the app starts
  using another required-reason API. `ITSAppUsesNonExemptEncryption` is `false`.
- Screenshots come from `testScreenTour` (6.9" iPhone 17 Pro Max, 1320×2868).
- Privacy policy: `PRIVACY.md` (no data collected). Support URL: the repo's Issues page.
- ⚠️ **The App Store Connect API cannot create an app record** — the first version needs
  App Store Connect → Apps → **+** (name, primary language, bundle id `com.billchan.BigTwo`,
  SKU), and the **App Privacy** questionnaire ("Data Not Collected") is web-only too.
  Xcode Cloud archives every push to `main`; `reference/archive.md` in the global
  `release` skill covers building locally when the quota is spent.
- App Store Connect app id **6811548119** ("Big Two 鋤大弟", primary locale en-US). Free;
  every territory except mainland China (a game there needs a license number).
- ⚠️ **No suit symbols in any App Store Connect text** — description, promotional text and
  TestFlight "What to Test" all reject ♠♦♣♥ (409 *invalid characters*), and a `<` in the
  description is refused as markup. Write "3 of diamonds".
- ⚠️ **No "Palm" anywhere a user or reviewer can read it** (guideline 2.3.10 — other
  platforms' names): app strings, store metadata, and TestFlight "What to Test" — which
  is why those notes carry the commit hash, not the branch name (`palm-square-layout`
  leaked that way). Say "the 1999 handheld game" / "the classic look". Type names like
  `PalmButtonView`, comments, README and the GitHub repo are fine. Removed from 1.0 (3)
  after 1.0 (2) had gone to review with the credit in About.
- **TestFlight**: internal groups mirror 周易占卜's ("App Store Connect Users", "testers")
  plus "me"; **"External Testers"** holds every 周易占卜 tester. Internal groups only
  accept people the API recognises as team members ("Tester(s) cannot be assigned"
  otherwise) — add those to the external group. Each new version's first build goes
  through Beta App Review before external testers get it, and **only one build per
  version can be in Beta App Review** (`ANOTHER_BUILD_IN_REVIEW`): add the next build to
  the group, submit it once the previous review finishes.
- Build numbers so far: 1.0 (1) old layout, 1.0 (2) square layout (submitted, then pulled),
  1.0 (3) = (2) without "Palm" + white status bar — **released 2026-09-19**. Marketing URL left
  empty on purpose: it pointed at the GitHub README, which tells the Palm story. Pass `CURRENT_PROJECT_VERSION=<n>` to `xcodebuild archive`; in zsh
  expand a flags variable with `${=AUTH}` (plain `$AUTH` is passed as one argument).
- ⚠️ **Export with the *other* key in `~/.appstoreconnect/private_keys/`, not `$ASC_KEY_ID`.**
  `$ASC_KEY_ID` is App Manager: export fails with *Cloud signing permission error* and
  *No profiles for 'com.billchan.BigTwo'*. The second key has Admin and exported 1.0 (1)
  on 2026-09-13 (that run also registered the bundle id). Same issuer id for both.

## State of play

Single-player against three bots is complete and runs on the simulator; 47 kit tests and
10 UI tests pass (see `docs/test_runs.md`). Open items, roughly in order:

1. App Store: **1.0 is live (released 2026-09-19)** — still untagged, tag `v1.0` at the
   commit it was built from. `main` is **1.1** (iOS 15+, seven UI languages); Xcode Cloud
   archives each push. ⚠️ The store listing is **en-US only** and the live 1.0 binary
   declares English only (`languageCodesISO2A: ['EN']`); the localized listing text and
   per-locale screenshots are ready in `docs/store/`, but each locale has to be created
   in App Store Connect by hand first. ⚠️ No App Store Connect API key exists on this
   Mac (`~/.appstoreconnect/private_keys/` is absent), so every store step — listing
   builds, uploading screenshots, submitting — is web-only until one is made.
2. Save the game in progress — killing the app loses a 10-deal game.
3. High-score table — name entry, total rounds, total seconds, max score in one game,
   score balance (as in v2.2).
4. Pass-and-play multiplayer: `Seat.isHuman` already drives the loop; it needs the
   "Next Player's Turn" cover screen that hides the previous player's hand.
5. Landscape layout / iPad.
