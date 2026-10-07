# Setting up the Apple Watch in-app purchase

**Submitted 2026-10-07.** Review submission `226e35df-5f4b-4d0e-997a-ea3db685c47e` is
`WAITING_FOR_REVIEW` with version 1.3 build 105 and this purchase. Live price is
US$10.99 — the table below still says $4.99 because it is the 2026-09-30 handoff.
Do not create the product again, do not change the price, and do not turn the paywall off.

Handoff written 2026-09-30 from a Claude Code session. The watch app and its StoreKit
code are finished and merged into the `watch-app` branch; the **product does not exist in
App Store Connect yet**, and that is the only thing standing between the code and a
working purchase.

---

## 1. What has to be created

App Store Connect → **Big Two 鋤大弟** (Apple ID `6811548119`) → Monetization →
In-App Purchases → **+**

| Field | Value |
| --- | --- |
| Type | **Non-Consumable** |
| Product ID | `com.billchan.BigTwo.watch` |
| Reference Name | `Watch app` |
| Price | **Tier 5 — US$4.99**, all territories |
| Cleared for Sale | Yes |

⚠️ A product ID is permanent: it cannot be deleted and reused. `com.billchan.BigTwo.watch`
is the exact string `WatchUnlock.productID` and `Configurations/BigTwo.storekit` both use —
a typo means the app looks for a product that will never exist.

### Localizations (six, matching the store listing)

Display name is capped at 30 characters, description at 45.

| Locale | Display Name | Description |
| --- | --- | --- |
| en-US | `Play on your Watch` | `Play the full game on your wrist.` |
| zh-Hant | `手錶版鋤大弟` | `在手錶上打完整的一局。` |
| zh-Hans | `手表版大老二` | `在手表上打完整的一盘。` |
| vi | `Big Two trên đồng hồ` | `Chơi trọn ván ngay trên cổ tay.` |
| id | `Main di jam tangan` | `Mainkan permainan penuh di pergelangan tangan.` |
| ms | `Main pada jam tangan` | `Main permainan penuh pada pergelangan tangan.` |

⚠️ **No "Apple Watch" in the display name.** Apple's trademark guidelines do not allow an
Apple product name inside a product name, and it is a common rejection. The paywall copy
inside the app (`Big Two on Apple Watch`) is descriptive use and is fine where it is.

### Review notes

```
Unlocks the Apple Watch game. The watch app ships inside the phone app
and always installs; this purchase decides whether it plays or shows
the paywall. Open the watch app to see it.
```

### Two things that still block submission

- **Review screenshot**, at least 640×920. The committed watch captures in
  `screenshots/watchos/` are 416×496, too small — a fresh capture or an upscale is needed.
  Without it the product sits in *Missing Metadata*.
- **Paid Applications Agreement.** Big Two has only ever been free, so this has probably
  never been signed. Without it the product cannot be sold. ASC → Business → Agreements,
  Tax, and Banking.

---

## 2. Why this could not be done from the command line

Three routes were tried and all are closed on this machine — worth recording so nobody
spends the time again:

| Route | Result |
| --- | --- |
| `Spaceship::Tunes` IAP API (fastlane) | `Spaceship::Tunes::Error: Not Found` — Apple retired the endpoint |
| `Spaceship::ConnectAPI` | No in-app-purchase models exist at all in fastlane 2.240.1 |
| `~/.claude/skills/release/scripts/asc.swift` | Commands are builds / submissions / cancel-review / screenshots / whats-new — no IAP |
| Claude in Chrome | Extension not connected in this session |

IAP management now lives on the App Store Connect API's `inAppPurchasesV2` resource, which
needs a JWT signed with a `.p8` private key. There is **no API key on this Mac**
(`~/.appstoreconnect/private_keys/` does not exist), and the Apple ID web session cannot
reach that endpoint.

---

## 3. The better fix: make an API key

One key unlocks everything that was web-only in that session, not just this product.

1. ASC → **Users and Access → Integrations → App Store Connect API** → generate a key.
   Give it **Admin** — App Manager is not enough (it cannot do cloud-signed exports).
2. Download the `.p8` **once** — Apple will not offer it again.
3. `mkdir -p ~/.appstoreconnect/private_keys` and put the file there.
4. Export `ASC_KEY_ID` and `ASC_ISSUER_ID`.

What that would then unblock, all of which was manual in that session:

- creating and editing this in-app purchase
- the `beta review slot` preflight in `.claude/release.json`, which could not run
- screenshot upload through `asc.swift screenshots` instead of `deliver --overwrite_screenshots`,
  the path with the recorded silent failure
- `asc.swift submissions` as the read-back after submitting for review
- exporting an archive locally (`Cloud signing permission error` without an Admin key)

---

## 4. Where the code stands

- `Shared/WatchUnlock.swift` — StoreKit 2, non-consumable, reads `Transaction.currentEntitlements`
  on the watch itself. Entitlements follow the Apple ID, so nothing syncs from the phone.
- `BigTwoWatch/Views/WatchStoreView.swift` — the paywall: Buy (with price) and Restore.
- ⚠️ **`BigTwoWatchApp.paywallEnabled` is `false`.** It was turned off precisely because the
  product does not exist — a paywall with nothing to buy locks the game with no way past
  it. **Flip that one constant back to `true` once the product is live.**
- `Configurations/BigTwo.storekit` holds a local copy of the product, wired to the
  `BigTwoWatch` scheme, so the purchase can be exercised from Xcode without the real store.
  ⚠️ `simctl launch` does **not** apply it; only a run from Xcode does.

### Not yet verified

- **The purchase has never run end to end.** `Product.purchase()` has not been called once.
  What is verified is the paywall, the price-less fallback and the `.unavailable` branch.
  Running the `BigTwoWatch` scheme from Xcode against `BigTwo.storekit` finishes that check.
- **Phone ↔ watch preference sync** (`Shared/PreferenceSync.swift`) is written and both
  targets compile, but no setting has been watched crossing from one device to the other.
  It needs a paired phone and watch; the simulator pair cannot be driven from one
  `xcodebuild` run.

### Other open items from that session

- PR #19 — AdMob banner. CI green. Ad ids are still Google's public **test** ids, in
  `BigTwoApp/AdUnits.swift` and `GADApplicationIdentifier` in `project.yml`; both must be
  swapped before ads ship. The App Store "App Privacy" answers still say *Data Not
  Collected*, which stops being true with AdMob — web-only to change.
- PR #20 — the watch app, this purchase, the gestures and the preference sync. CI green
  after registering the App ID `com.billchan.BigTwo.watchkitapp` ("Big Two Watch") on
  2026-09-30 — cloud signing creates profiles but never identifiers, which is why the
  ad-hoc export failed with exit 70 until it existed.
- The 4.7" (750×1334) screenshot set went up with 1.2. v1.2 is `WAITING_FOR_REVIEW` with
  build 81 and will release automatically on approval.
- No entry point on the phone sells this product; the watch paywall is the only place it
  appears. A row in About would sell it far better and needs copy in seven languages.
