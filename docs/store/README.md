# App Store listing

One directory per App Store locale, in fastlane's `deliver` filenames, so this can be
uploaded by hand today and by a tool the day one is wired up.

```
docs/store/metadata/<locale>/{name,subtitle,keywords,description,release_notes}.txt
docs/store/screenshots/<locale>/NN_<name>.png              # 1320×2868, 6.9" iPhone
docs/store/screenshots/<locale>/iphone47_NN_<name>.png     # 750×1334, 4.7" iPhone
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
is the one thing the website is otherwise needed for, and it takes this layout as-is.
`fastlane/Deliverfile` already carries both paths, `skip_binary_upload`, `force` and the
precheck flag, so the upload is one line — run it yourself, the session prompt is
interactive (`! fastlane …`):

```bash
fastlane spaceauth -u <Apple ID>          # once; stores ~/.fastlane/spaceship/<id>/cookie
fastlane deliver --app_version 1.1 --overwrite_screenshots true
```

`--overwrite_screenshots` matters now that each locale holds two device sets: without
it deliver *adds* to what is on the store and everything past Apple's 10-per-device cap
is dropped. There is no App Store Connect API key on this Mac; with one it would be
`--api_key_path "$(python3 ~/.claude/skills/release/scripts/asc_key_json.py)"`.

Then read the screenshots back — a green deliver is not evidence:

```bash
fastlane deliver download_screenshots --app_version 1.1 --screenshots_path /tmp/store_shots
ls /tmp/store_shots/en-US | grep -c APP_IPHONE_47     # expect 5
ls /tmp/store_shots/en-US | grep -c APP_IPHONE_67     # expect 5
```

- ⚠️ Give `download_screenshots` a path **outside the repo** — it defaults to
  `fastlane/screenshots/` and would overwrite the set just built. Compare the image, not
  a checksum: Apple re-encodes on upload.
- `docs/store/metadata/` holds locale directories only — `fil/` is not there (Apple has
  no Filipino metadata locale), and nothing else may sit beside them.
- ⚠️ Screenshots through `deliver` are the path with the recorded silent failure —
  read them back, or upload them with `asc.swift screenshots` instead
  (`~/.claude/skills/release/reference/screenshots.md`).

## Screenshots

⚠️ Screenshots belong to a **version**: a released one cannot be re-shot, so the 4.7"
set lands on the 1.1 listing and reaches those devices when 1.1 ships.

⚠️ **The listing needs a 4.7" set as well as the 6.9" one.** An iPhone SE / 6s on
iOS 15 — the app ships iOS 15+ — showed **no screenshots at all** on the product page:
the old App Store client does not fall back to the 6.9" images. Apple's documented
chain is 4" ← 4.7" ← 5.5" ← 6.1" ← 6.5", so a 4.7" set covers both remaining
iOS 15 screen sizes. Do not upload only `NN_*.png` again.

The 4.7" files are **derived, not captured**: no runtime on this Mac can take them any
more (Xcode 27 ships only iOS 27, which refuses `iPhone SE (3rd generation)` and every
other 4.7"/5.5" device — `simctl create` answers *Incompatible device*).

```bash
python3 scripts/make_47_screenshots.py            # writes iphone47_*.png beside the sources
python3 scripts/make_47_screenshots.py --check    # non-zero if one is missing or older
```

The bezel around the square is a flat #212121, so the script drops bands of it until
the frame is 16:9 — the status bar and the game are untouched — and only then scales
1320 → 750. The framing lands where the native capture in `screenshots/ios-se/` put it (that set was
taken on an iOS 26.3 SE, before the runtime went away) — and it carries the frozen 9:41
clock those native shots never got. Re-run it after regenerating any 6.9" shot.

`fastlane deliver` files a screenshot by its **pixel size**, so both sets can sit in the
same locale directory; `asc.swift` files it by the `iphone47_` prefix
(`screenshots.displayTypes` in `.claude/release.json`). Within a device size the order is
the filename order, so `iphone47_01_trick` … `iphone47_05_menu` matches the 6.9" order.


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
