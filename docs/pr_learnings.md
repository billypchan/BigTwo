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

## fix-autopass-five-card — 五張打不過也要自動過

**截圖看起來像 bug，其實是 Palm 的預設。** `autopass` 預設開，`autopassFiveCard`
預設關。桌上五張時 `advance()` 的條件 `table.count < 5 || autopassFiveCard` 不成立，
人類就坐在 Pass 上 — Deal 4，Adam 的 7♦ 8♣ 9♦ 10♠ J♦，Bill 只有 34567 / 23456
兩條順，標準規則都打不過。

**只改預設救不了已安裝的人。** 偏好已經寫進 UserDefaults，`decodeIfPresent` 會留下
`false`。所以把五張閘拿掉：`autopass == true` 且 `!canBeat` 就過。

**港式規則下同一手可以回。** HK 把 23456 變最大順；Bill 手裡有 2-3-4-5-6，
`canBeat` 為 true，不能自動過。測試要兩套 rules 都釘住。

**偏好表上的第二個勾仍留著（Palm 用詞），但 Game 不再讀它。** 拖下去改 copy
會變另一個 PR。

---
