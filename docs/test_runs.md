# Test runs

One line per run — see CLAUDE.md § "After every UI test run". Deliberate failures are
evidence that a test can fail; they stay in the log.

- 2026-09-13 01:10 — BigTwoKit ✓ 31/31 (`swift test`, first suite: Card/Play/Game/PreferencesStore)
- 2026-09-13 01:20 — iOS (iPhone 17 Pro Max, 26.3) ✗ 3/8 (fail: testLead, testIllegalPlay, testLongPress, testDoubleTap, testScreenTour — per-card tap gestures lost edge taps to the overlapping neighbour; fixed with one row gesture)
- 2026-09-13 01:26 — iOS ✓ 8/8 (full GameUITests + testScreenTour)
- 2026-09-13 01:30 — iOS ✓ 1/1 but should have failed — testScoreSheet_swipeDownDoesNotDismissIt passed with the sheet made dismissable: `sheet.swipeDown()` never moves a sheet. Rewritten as press-and-drag
- 2026-09-13 01:33 — iOS ✗ 0/1 deliberate (testScoreSheet_swipeDownDoesNotDismissIt, sheet made dismissable) — press-and-drag test now fails when it should
- 2026-09-13 01:34 — BigTwoKit ✗ 0/1 deliberate (rejectsCardsFromAnotherHand, ownership guard removed), then ✓ 31/31 restored
- 2026-09-13 01:47 — iOS ✗ 0/1 deliberate (testScoreSheet_swipeDownDoesNotDismissIt, sheet made dismissable, after the settle-wait change)
- 2026-09-13 01:50 — iOS ✓ 8/8 (full suite; screen tour re-extracted to screenshots/ios)
- 2026-09-13 06:20 — BigTwoKit ✗ 40/46 (new BotPlayerTests: test typos — ♦ sorts before ♣, human is seat 1) · 301 s
- 2026-09-13 06:28 — BigTwoKit ✓ 46/46 · 79 s after enumerating five-card hands once per pool
- 2026-09-13 06:31 — BigTwoKit ✓ 46/46 · 27 s (3 whole-game seeds, 8 strength games; greedy seat −719)
- 2026-09-13 06:33 — BigTwoKit ✗ 13/15 deliberate (BotPlayerTests with the fellow-bot and two-pair rules removed), then ✓ 15/15 restored
- 2026-09-13 06:42 — iOS (iPhone 17 Pro Max, 26.3) ✗ 5/7 + 1 restart (testLead, testIllegalPlay read state straight after a tap; testLaunch timed out waiting for idle — load average 50–74, disk 99 % full)
- 2026-09-13 06:46 — iOS ✗ 2/3 (testLead: isSelected read too early) — same load
- 2026-09-13 06:50 — iOS ✓ 8/8 (full suite, tests now wait for state; load 70) · screenshots re-extracted
- 2026-09-13 11:40 — BigTwoKit ✓ 47/47 (lastActions, gameSpeed/sortBySuit decoding)
- 2026-09-13 11:55 — iOS — aborted: disk full (ENOSPC) mid-run; stopped, user freed space
- 2026-09-13 12:20 — iOS ✗ 8/10 (Palm square layout; testLongPress and testDoubleTap failed under load average ~55 — long press read as a tap, Clear tap lost) · screenshots extracted (6-shot tour)
- 2026-09-13 12:25 — iOS ✓ 2/2 (the two gesture tests alone, load ~13)
- 2026-09-13 12:35 — iOS ✗ 9/10 (testLongPress fixed by judging on event timestamps; testDoubleTap still 1/6 — compared touch-up times, ≈0.3 s apart for XCUITest's double tap)
- 2026-09-13 12:45 — iOS ✓ 3/3 (gesture tests: double tap measured touch-down to touch-down, 0.4 s)
- 2026-09-13 12:50 — iOS (iPhone 17 Pro Max, 26.3) ✓ 10/10 (full suite, Palm square layout) · 6-shot tour re-extracted and viewed
- 2026-09-13 13:10 — iOS (iPhone 17 Pro Max, 26.3) ✓ 10/10 (Palm removed from About; white status bar) · tour re-extracted, status bar checked
- 2026-09-13 13:45 — BigTwoKit ✓ 47/47 · iOS ✗ 9/10 (iOS 14 deployment target; testScreenTour: Preferences dialog didn't open after the menu tap, line 32)
- 2026-09-13 13:50 — iOS ✓ 1/1 ×2 (testScreenTour alone, twice — a flake, 1 in 4 full runs so far; watch it)
- 2026-09-13 13:50 — iOS 14 / 13 compile check: kit + app typecheck at `arm64-apple-ios14.0-simulator` → 0 errors; at 13.0 → 14 errors (SwiftUI App lifecycle)
- 2026-09-19 12:42 — iOS (iPhone 17 Pro Max, 26.2) ✗ 0/1 testPreferences_surviveARelaunch — relaunch tapped menu_preferences before the menu appeared
- 2026-09-19 12:44 — iOS (iPhone 17 Pro Max, 26.2) ✓ 1/1 testPreferences_surviveARelaunch (wait for the menu item after the title tap)
- 2026-09-19 12:55 — iOS SE (3rd gen, 26.3) ✗ 4/5 (double-tap + About ✓; testScreenTour: title tab 22u, menu tap missed)
- 2026-09-19 13:00 — iOS SE (3rd gen, 26.3) ✓ 5/5 (3 double-tap, About SharedKit, screen tour)
- 2026-09-19 13:03 — iOS SE (3rd gen, 26.3) ✓ 1/1 testScreenTour after Play/Pass gap · screenshots/ios-se
- 2026-09-19 13:12 — iOS (iPhone 17 Pro Max, 26.2) ✓ 1/1 testScreenTour (+ Final Score, `-dealsPerGame 1`) · 7 shots in screenshots/ios
- 2026-09-19 13:18 — iOS (iPhone 17 Pro Max, 26.2) ✓ 1/1 testScreenTour (+ About) · 8 shots in screenshots/ios
- 2026-09-19 13:39 — BigTwoKit ✓ 56/56 (StrongBot) · iOS (iPhone 17 Pro Max) ✓ 2/2 testPreferences + testScreenTour
- 2026-09-19 13:48 — BigTwoKit ✓ 55/55 (StrongBot: no peek, fights fellow bots; 1 Strong vs 3 greedy +220)
- 2026-09-19 21:43 — BigTwoKit ✓ 55/55 · iOS (iPhone 17 Pro Max, 26.3) ✓ 13/13 (`Shared.xcconfig`; `IPHONEOS_DEPLOYMENT_TARGET=15.0`)
- 2026-09-19 22:36 — BigTwoKit ✓ 55/55
- 2026-09-19 22:42 — iOS (iPhone 17 Pro Max, 26.3) GameUITests+ScreenTour 8 passed then runner crash on first launch of `testAbout` / `testIllegalPlay`; rerun ✓ 2/2 those two. Screen tour extracted; score/final_score PNG diffs are deal numbers, not committed.
- 2026-09-19 23:12 — BigTwoKit ✓ 63/63 (8 PlayerName tests; `resolvedNames` nonisolated). iOS (iPhone 17 Pro Max, 26.3) ✓ 1/1 `testNames_customNameShowsOnTheTableAndSurvivesARelaunch`
