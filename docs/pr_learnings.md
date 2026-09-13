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

## palm-style-bot — 依行為重寫原版 AI、MIT 開源

**原始碼是 GPL，所以只准「依描述重寫」，不准翻譯。** 先把 `cstate.cpp` 的行為寫成規格（出牌順序、
留牌規則、偷看、讓同伴），再用 `PlayFinder` 的架構重新實作；原版是 char 陣列 + 一連串 Strip，
結構完全不同。這條規則已寫進 CLAUDE.md。

**「偷看」與「讓同伴」照原版保留。** Palm 的 bot 看得到所有人的手牌、也不搶同伴 bot 的 K/A/2
單張。拿掉任一項遊戲都會變簡單；兩者各有測試釘住。

**強度用數字看，不用感覺。** 舊的貪心 bot 留在測試 target（`GreedyBot`）當量尺：它坐人類位、
對上三個 Palm 式 bot，固定 seed 8 局累計 −719（20 局 −1756）。之後改 AI 若這個數字變大，
就是變弱。

**新 AI 讓整套測試從 10 秒變 301 秒。** 每次決策都會列舉 C(13,5)=1287 種五張組合，而且每種牌型
各列舉一次、留牌時每一輪又重列。改成每組牌只列舉一次（`Fives`）、組合改用迴圈產生、`canBeat`
找到一個就停 → 79 秒；再把整局測試縮成 3 個 seed、強度測試 8 局 → 27 秒。Debug 編譯的 Swift
在這種迴圈上特別慢；Release 版 App 裡每步只要幾毫秒。

**⚠️ `BotContext.hands` 的第二格才是人類。** 行為測試的 `others:` 參數依座位 1、2、3 排列，
第一次把「人類剩兩張」寫成座位 2，測的其實是 bot。

**牌的代碼是 Big Two 順序：♦ 在 ♣ 前。** 一對五是 `"5d 5c"`，不是 `"5c 5d"` —— 四個斷言因此
第一次就錯。

**磁碟只剩 3 GB 時 UI 測試會亂。** 負載衝到 50–75，模擬器慢到點擊還沒生效就被讀取；
`isSelected` 讀到 false、「出牌」在第二張牌選上之前就按下。測試改成先等狀態再往下。

**`git stash -u` 碰上「搬走舊檔 + 同路徑新檔」會還原失敗**（`already exists, no checkout`）。
已追蹤的改動會回來，未追蹤的新檔留在 stash 裡；用 `git show 'stash@{0}^3:<path>'` 比對後再 drop。

**API 建不了 App。** App Store Connect API 可以查、可以改 metadata、可以送審，但 `POST /v1/apps`
不存在 —— 第一次上架一定要到網頁建 App 紀錄；App Privacy 問卷也只能在網頁填。

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
