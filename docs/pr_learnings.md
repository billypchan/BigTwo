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

## screenshots-clock — 狀態列時鐘不要進 git diff

**截圖是整台模擬器，含系統時鐘。** 每次 tour 時鐘不同，PNG 整張都變。`extract_screenshots.py` 解 PNG，略過最上面 8%（Dynamic Island + 時鐘），底下一樣就保留舊檔。`--force` 才覆寫。新圖要 9:41：`scripts/freeze_status_bar.sh <udid>`（scheme test preAction 會試 `booted`）。

---

## strong-bots-fair — 不偷看、也打同伴

**3 個會互打的 Strong 對 1 個 greedy 會輸。** 不許偷看、不許讓同伴的 K 過，三個 Strong 互相蓋牌，greedy 坐收 +271。量尺改成 1 Strong vs 3 greedy（+220）。Classic 仍偷看、仍讓同伴。

---

## strong-bots — 新 AI 不能整套重寫最便宜出牌

**對 greedy 的 −719 是 Classic 的量尺，不是「愈聰明愈負」。** 第一版 Strong 一有機會就出最大鎖死牌（先倒 2♠），greedy 8 局變成 +389。改成 Classic 出牌 + 三條覆蓋：整手能出就出、你剩一張用剛好壓死的單張、你 ≤5 張且能吃同伴的牌才蓋。之後 greedy −517、Classic 當人類 −505。

---

## se-doubletap — 雙擊對子、SE 版面

**44pt 點擊框不跟正方形縮放。** Play/Pass 旁邊的 icon 在 SE（u≈1.17）佈局是 44pt，不是 20 Palm 單位；`left: N` 會伸進按鈕底下。每列加 `trailingReserve = controlsWidth + 16u`，牌列 `layoutPriority(-1)` 讓出空間。Pro Max 上看不出來，一定要在 SE 截圖。

**標題分頁只有 22u，SE 上約 26pt，XCUITest 會點空。** `menu_button` 加上 44pt 點擊高度；tour 點一次沒出選單就再點一次。

**少於 5 張同花的雙擊不要選那門花色。** 改成有對就選對，沒有就不動（第一次 tap 已經選了那一張）。seed 2 的 8♥ 是對、6♥ 不是、Q♣ 有 6 張♣。

**Final Score 不要真的打 10 局。** `-dealsPerGame 1` + autoplay 第一張分數表就是 Final Score / New Game。標題列會顯示 Deal 1/1。Tour 加 About 後編號是 06_about、07_score、08_final_score — 舊的 06_score 檔要刪掉，否則 repo 裡會留兩張。

---

## pref-source — Preferences 加 Source 開 GitHub

**選單點了不等就點下一項，重開後會失敗。** `testPreferences_surviveARelaunch` 第一次開 Preferences 過了（`pref_source` 也找得到），`terminate` 再 launch 後立刻點 `menu_preferences`：選單還沒出現。跟 Source 按鈕無關。改成先 `waitForExistence` 再 tap，跟 CLAUDE.md「等 tap 造成的狀態」同一條。

**Source 連公開 repo，不要連 `/settings`。** GitHub 的 `/settings` 是管理員頁，使用者打不開。

---

## palm-square-layout — Palm 正方形版面、記牌表、iOS 15

**參考圖要全部看過再動手。** 使用者只貼了一張 v2.2.8 的主畫面；SourceForge 上另外還有 10 張，
其中 `portrait.gif` 才是 iPhone 直向的答案：Palm 直向時是「上方正方形 + 下方記牌表」（記牌表放在
原本的手寫輸入區）。只照第一張圖做，iPhone 上下會空一大塊。

**Palm 的細節只有截圖看得到：** pass 顯示大字「PASS」、選中的牌是反白而不是抬起、排序圖示顯示
「按下會切成的順序」、選單從標題分頁往下拉、偏好設定的用詞（"Auto pass"、"Use Hong Kong Rule Set"）。
這些都寫進了 CLAUDE.md 的視覺規則。

**iOS 的 sheet 全部拿掉，iOS 15 相容幾乎是順便完成的。** `presentationDetents`、`NavigationStack`、
`LabeledContent` 都是 iOS 16 才有；改成畫在正方形裡的 Palm 對話框後，這些 API 一起消失。
剩下的只有 kit 裡的 `Duration` / `Task.sleep(for:)`，換成 `TimeInterval` / `nanoseconds`。
⚠️ 這台 Mac 沒有 iOS 15 模擬器（磁碟也裝不下），所以 iOS 15 只驗證到編譯。

**SwiftUI 的 `.plain` 按鈕停用時會把整個 label 調暗。** Palm 的停用按鈕是白色膠囊配灰字，被調暗後
變成半透明綠色。自訂一個 `ButtonStyle`（`PalmPressStyle`）就不會自動調暗，`.disabled()` 仍然有效，
所以 XCUITest 的 `isEnabled` 照樣能測。

**Palm 式的 modal 對話框靠一層透明底攔截點擊。** `Color.clear.contentShape(Rectangle()).onTapGesture {}`
放在對話框後面；少了它，點對話框外面會點到底下的手牌。這條由 `testScoreDialog_isModal` 測試。

**手勢判斷要用事件自己的時間戳記（`DragGesture.Value.time`），不要用處理當下的 `Date()`。**
主執行緒一卡，按下和放開的事件會一起送到：長按被當成點一下、雙擊的兩下被算成間隔太久。
而雙擊要量「按下到按下」：量「放開到放開」時，XCUITest 的 `doubleTap()` 間隔約 0.3 秒，
0.3 秒的門檻剛好卡住，在低負載下也穩定失敗。現在的門檻是 0.4 秒（UIKit 約 0.35 秒）。

**⚠️ UI 測試跑到一半把磁碟寫滿（`ENOSPC`）之後，連 Bash 都不能用** —— 每個指令都要先建立輸出檔。
只能停掉背景工作，請使用者清空間。之後的測試改用 `-resultBundlePath` 存到暫存區，擷取截圖後就刪掉，
不在 DerivedData 裡累積。

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
