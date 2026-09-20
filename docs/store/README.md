# App Store listing

One directory per App Store locale, in fastlane's `deliver` filenames, so this can be
uploaded by hand today and by a tool the day one is wired up.

```
docs/store/<locale>/{name,subtitle,keywords,description,release_notes}.txt
docs/store/screenshots/<locale>/NN_<name>.png     # 1320×2868, 6.9" iPhone
```

`.claude/release.json` points at both (`metadata.dir`, `screenshots.dir`), so
`swift ~/.claude/skills/release/scripts/asc.swift screenshots --version 1.1` can push
the screenshots once an App Store Connect API key exists on the machine.

## Before any of this can be uploaded

⚠️ **Each locale must be added in App Store Connect first** (App Information → the
language picker). A locale that has never been created there is invisible to every
upload tool no matter what is on disk — the tools enumerate the *store's*
localizations and then look for a matching directory.

⚠️ **Filipino may not be offered** in App Store Connect's localization list. The app
ships a `fil` UI and `fil/` is written here; if the list has no Filipino, leave that
storefront on English metadata — the app itself still runs in Filipino.

## Rules these files already follow

- **No suit symbols.** `♠♦♣♥` are rejected as *invalid characters* (409), and a `<` in
  the description is refused as markup. Write "3 of diamonds" / "3 rô" / "3 wajik".
- **No other platform's name** (guideline 2.3.10) — "the 1999 handheld game", never the
  name of the device it ran on.
- Limits, checked when these were written: name 30, subtitle 30, keywords 100,
  description 4000, release notes 4000.

## Screenshots

The five shots mirror what the store showed for 1.0, in the same order: trick,
selected cards, score sheet, preferences, menu. Apple allows up to 10 per device.

They are generated, not hand-made — the screen tour runs in any shipped locale:

```bash
xcodebuild test -project BigTwo.xcodeproj -scheme BigTwo \
  -destination 'platform=iOS Simulator,id=<udid>' \
  -only-testing:BigTwoUITests/ScreenTourUITests/testScreenTour -testLanguage vi
python3 scripts/extract_screenshots.py --latest <scratch>/vi --force
```

Then copy `ios_screen_03_trick`, `02_selected`, `08_score`, `05_preferences`,
`04_menu` into `docs/store/screenshots/<locale>/` under the numbered names.
⚠️ Freeze the clock first (`scripts/freeze_status_bar.sh <udid>`) — these all read 9:41.
