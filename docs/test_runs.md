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
