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
