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

⛔ **Filipino is not an App Store metadata language.** Apple's list — the one fastlane
carries as `FastlaneCore::Languages::ALL_LANGUAGES` — has no `fil` and no `tl`:

```bash
grep ALL_LANGUAGES "$(dirname "$(gem which fastlane_core)")/fastlane_core/languages.rb"
# ar-SA bn-BD ca cs da de-DE el en-AU … id it ja … ms nl-NL … vi zh-Hans zh-Hant
```

So the listing can be in six of the app's seven languages. `fil/` stays here as the
Filipino copy of record — the app runs in Filipino and the Philippines storefront
shows the English listing — but **do not** try to upload it; the locale will be
rejected.

## Every locale needs its own URLs

⚠️ A locale `deliver` creates starts with an **empty support URL**, and Apple requires
one per localization — the version then cannot be submitted, and the error names
nothing: *"appStoreVersions … is not in valid state"*. That is why every locale here
carries `support_url.txt` and `privacy_url.txt`; do not drop them from a new one.

## Rules these files already follow

- **No suit symbols.** `♠♦♣♥` are rejected as *invalid characters* (409), and a `<` in
  the description is refused as markup. Write "3 of diamonds" / "3 rô" / "3 wajik".
- **No other platform's name** (guideline 2.3.10) — "the 1999 handheld game", never the
  name of the device it ran on.
- Limits, checked when these were written: name 30, subtitle 30, keywords 100,
  description 4000, release notes 4000.

## Uploading with fastlane

`deliver` **creates a localization that doesn't exist yet** from the directory, which
is the one thing the website is otherwise needed for. It takes this layout as-is:

```bash
KEYJSON=$(python3 ~/.claude/skills/release/scripts/asc_key_json.py)
fastlane deliver --api_key_path "$KEYJSON" --app_version 1.1 \
  --metadata_path docs/store --screenshots_path docs/store/screenshots \
  --skip_binary_upload --force --precheck_include_in_app_purchases false
```

- Needs credentials: the API key above, or `-u <Apple ID>` with the password and 2FA
  typed in (interactive — run it yourself with `! fastlane …`).
- Drop `docs/store/fil` out of the way first, or deliver will reject the locale.
- ⚠️ Screenshots through `deliver` are the path with the recorded silent failure —
  read them back, or upload them with `asc.swift screenshots` instead
  (`~/.claude/skills/release/reference/screenshots.md`).

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
