# PR Learnings

One entry per PR / branch, **newest first**. Written at the end of the work, before
or with the push — see CLAUDE.md § "PR Learnings".

Record only what would have saved time if it had been known at the start:
non-obvious framework behaviour, project-specific gotchas, decisions whose
rationale isn't visible in the diff, and anything that bit us. Skip "what the PR
does" — the commit message and the diff already say that.

Durable *rules* get promoted into CLAUDE.md as well; the entry here keeps the story
and the evidence.

---

## production-foundation — XcodeGen、BigTwoKit、UI 測試

**重疊的牌不能各自掛 tap gesture。** 13 張牌疊成一排，每張只露出約 30pt。每張牌自己
`.onTapGesture` 時，點在 3♦ 露出區、離 4♣ 邊緣 3pt 的地方，選到的是 4♣ —— SwiftUI 的
觸控容差（touch slop）把接近邊緣的觸點交給 zIndex 較高的鄰牌。XCUITest 點元素正中央，
所以 5 個測試同時失敗；真手指更粗，裝置上只會更糟。改成整排一個
`DragGesture(minimumDistance: 0)`，用 x 座標除以間距決定是哪張牌；長按在按住 350ms 時觸發，
不等放開。VoiceOver 走每張牌的 `accessibilityAction`。

**`XCUIElement.swipeDown()` 拉不動 sheet。** 分數表的「滑不掉」測試在拿掉
`.interactiveDismissDisabled()` 之後照樣通過 —— 手勢根本沒作用。改成
`coordinate.press(forDuration:thenDragTo:)` 從 sheet 頂緣內側往下拖，才在「故意弄壞」的版本
上失敗。另一個發現：唯讀 binding（`set: { _ in }`）本身就擋得住下滑關閉，兩道防線各自足夠。

**`waitForExistence` 成立時 sheet 還在滑入。** 截圖裡 OK 按鈕半截在螢幕外，看起來像版面 bug；
印出 frame 才知道一秒後 OK 在 y≈744/956，完全正常。之前加的「OK 必須在畫面內」斷言在壞版本上
照樣通過（因為 bug 不存在），所以刪掉。截圖前改用 `waitUntilSettled`（frame 連續兩次相同）。

**iOS 26 的 medium detent sheet 是半透明 liquid glass。** 手牌透過分數表模糊可見，違反「無模糊」
規則。`presentationBackground(Color.chrome)`（iOS 16.4+，包在 `palmSheetBackground()`）。

**`Text("*WIN!*")` 會變成斜體 WIN!** —— 字面字串是 `LocalizedStringKey`，會解析 Markdown。
Palm v2.2 特地加的星號要用 `Text(verbatim:)`。

**`swift scripts/make_app_icon.swift` 會讓直譯器當掉**（AppKit 繪圖）；用 `swiftc` 編譯再跑。
`NSGraphicsContext(bitmapImageRep:)` 對 24bpp 無 alpha 的 rep 回傳 nil，要 `bitsPerPixel: 32`
（noneSkipLast）—— App Store 圖示不能有 alpha。

**規則在牌局中途改會重排桌面。** 港式規則開關改成下一副牌才生效（`BigTwoGame.rules` 在發牌時
從 `preferences` 取一次）。

**Seed 2 讓玩家拿到 3♦ 先出**（`3d 4c 6h 8h 8s 9c 9s Tc Jd Jc Qc Ad 2c`）—— 有三對、六張梅花，
長按／雙擊測試都靠它。`shuffled(using:)` 只在同一個 toolchain 內穩定，換 Xcode 後若 UI 測試
的牌不對，先重找 seed。
