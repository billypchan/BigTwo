# Filipino listing — cannot be uploaded

`fil/` holds the Filipino store copy written alongside the other six. It lives here,
**outside `docs/store/`**, because Apple has no Filipino App Store localization: the
list fastlane carries as `FastlaneCore::Languages::ALL_LANGUAGES` has neither `fil`
nor `tl`.

```bash
grep ALL_LANGUAGES "$(dirname "$(gem which fastlane_core)")/fastlane_core/languages.rb"
```

Anything inside `docs/store/` is a locale `deliver` will try to create, so a `fil`
directory there fails the whole upload. The app still runs in Filipino; the
Philippines storefront shows the English listing.
