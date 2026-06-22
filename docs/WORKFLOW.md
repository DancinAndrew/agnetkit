# 工作流程：OpenSpec ↔ ECC 交接

agentkit 依序執行兩個系統。OpenSpec 負責**做什麼 / 為什麼**（規格）。ECC 負責**怎麼做**（執行 + 驗證）。`CLAUDE.md` 中的 Karpathy 原則管轄兩者。

```
            ┌─────────────────────────────────────────────────────────┐
            │  這個想法在你腦袋裡還很模糊嗎？                            │
            │  是 → grill-me（一次一題逼到零模糊）[選用]                 │
            │  spec 寫好後 → adversarial-spec-review（攻擊 spec）[選用] │
            └───────────────────────┬─────────────────────────────────┘
                                    ▼
            ┌─────────────────────────────────────────────────────────┐
            │  這個改動是非 trivial 的嗎？（見下方決策規則）               │
            └───────────────┬───────────────────────────┬─────────────┘
                       是   │                       否   │
                            ▼                            ▼
                   ┌─────────────────┐          ┌──────────────────┐
                   │  OpenSpec 路線  │          │   快速路徑路線    │
                   └────────┬────────┘          └────────┬─────────┘
   /opsx:propose "<idea>"   │             /plan（選用，輕量）或
   → proposal.md            │             直接 TDD                  │
   → design.md              │                            │
   → tasks.md（這就是計畫   │                            │
   與使用者對齊 ◀────────── 不要再 /plan）                │
                            │                            │
                            ▼                            ▼
                   ════════════ ECC 執行迴圈（per 任務）════════════
                   1. search-first   （寫 code 前先研究）
                   2. tdd-workflow   （RED = 把規格 scenario 寫成失敗測試
                                       → GREEN → REFACTOR，修改行 ≥80% coverage）
                   3. reviewer agents（code / security / python / fastapi / mle / db）
                   4. verification-loop / eval-harness（循環直到達成標準）
                   ══════════════════════════════════════════════════
                            │
                            ▼
                   更新 sysdoc/（若系統形狀改變——見 CLAUDE.md §3.5）
                            │
                            ▼
                   /opsx:archive（僅規格優先路線——把規格摺疊回去）
                            │
                            ▼
                   quiz-me（鞏固對剛做完東西的理解）[選用]
```

## 決策規則——走哪條路？

走 **OpenSpec（規格優先）**，若*任一*為真：
- 新功能或新模組；
- 需求模糊或有多種合理解讀；
- 涉及 **auth、付款、金錢，或資料模型 / migrations**；
- 跨越多個檔案或服務；
- 改變外部可觀察的行為。

否則走**快速路徑**：錯字、註解、格式、一行修改、明確範疇的局部改動。若行為有改變，仍要先寫失敗測試。

> 不確定走哪條？就走規格優先。這是最便宜的保險，防止做出錯誤的東西。

## 為什麼要分這兩條路（tradeoff）

OpenSpec 和 ECC 都有「計畫」介面，所以沒有規則的話它們就會重疊，讓你計畫兩次。清晰的邊界：

- **OpenSpec = 問題定義。** `proposal.md`（為什麼）、`specs/`（需求 + scenarios）、`design.md`（技術方法）、`tasks.md`（checklist）。這是審查者（或未來的你）為了理解意圖而讀的產物。也是 FDE / 顧問的肌肉：一份*什麼被同意了*的書面記錄。
- **ECC = 實作。** 它的 `planner`/`architect` 代理把*已批准*的任務轉化為 code 結構；`tdd-guide` 強制測試優先；reviewer 代理捕捉缺陷。ECC 不決定*是否*建造——OpenSpec 已經解決了那個問題。

交接點：**`tasks.md` 是契約。** OpenSpec 產出它；ECC 一次消費一個項目。不要讓 ECC 重新打開屬於 proposal 的範疇問題，也不要讓 OpenSpec 規定屬於 TDD 的實作細節。

## 三個工具都在「寫 code 之前」——用哪個？

`grill-me`、`/plan` 和 `/opsx:propose` 都在你寫 code 之前發生，所以它們看起來是重複的。它們不是——它們產出不同的東西：

| 工具 | 產出 | 是否保存？ | 何時用 |
|------|------|------------|--------|
| `grill-me` | 清晰度（一份摘要） | 否 | 想法在你自己腦袋裡還很模糊時 |
| `/opsx:propose` | `proposal/design/tasks.md` | 是（已 archived） | 非 trivial 的改動（規格優先路線） |
| `/plan` | 對話中的 checklist | 否 | 小 / 中型改動，想要步驟但不需要儀式感 |

**消除混亂的規則：**

- `/plan` 和 `/opsx:propose` 是**同一件事的輕重版——選一個，不要兩個都跑。**
  在規格優先路線，`tasks.md` *就是*你的計畫；在它上面再跑 `/plan` 是計畫了兩次。在快速路徑路線，`/plan` 是輕量選項（或直接跳 TDD）。
- `grill-me` 在**兩者之前**。它是前置步驟，不是替代品：它把「我大概知道我想要什麼」轉化為具體到可以寫下來的東西。腦袋清楚了？跳過它。

## 「opsx:propose → tdd-workflow 會讓規格漂移嗎？」

不會——*前提是*你尊重把它們連結在一起的因果鏈：

```
規格 scenarios  →  成為你的 RED 測試  →  測試驅動 code
```

OpenSpec 改動中的 `specs/` 目錄保存著需求**和 scenarios**。你的第一個 TDD 步驟（RED）是把其中一個 scenario 編碼為失敗測試。所以 code 不是在*平行*於規格執行（可以自由漂移）——它是被規格*拉著走*，透過測試。一條鏈，不是兩條平行軌道。

真正造成漂移的唯一原因：在實作途中發現規格是錯的或不完整的，然後**悄悄地繞過它**。不要這樣做。正確的做法是回去修改 proposal，然後讓 `/opsx:archive` 把最終規格與實際建造的東西對齊。規格不會自己漂移——是你繞過它才漂移的。

## 實際範例（規格優先）

```
grill-me                  → （想法很模糊）一次一題的問題揭露了
                            雙重收費的 race condition、重試語義、key TTL
/opsx:propose "add idempotent ticket purchase endpoint"
  → 審閱 proposal.md（為什麼：雙重收費 bug）、design.md（idempotency key 放 Redis）、
    tasks.md（1. schema、2. endpoint、3. concurrency 測試、4. 文件）

# task 1
search-first            → 讀現有付款 + schema code，確認 Redis 可用
tdd-workflow            → 失敗的 migration 測試 → 最小 migration → refactor
database-reviewer       → 檢查 migration + query plan

# task 2..3
tdd-workflow            → 失敗的 concurrency 測試（兩個平行購買，只收一次費）→ 實作
security-reviewer       → auth + idempotency key 的 replay-attack 檢查
fastapi-reviewer        → endpoint 契約、status codes、error shape
verification-loop       → 所有 tasks 的成功標準全綠

/opsx:archive           → 規格摺疊回去
sysdoc/ARCHITECTURE.md  → 記錄 idempotency-key 決策 + tradeoffs
sysdoc/RUNBOOK.md       → 加入新 env vars（REDIS_URL、IDEMPOTENCY_TTL）
sysdoc/OVERVIEW.md      → 在元件表中記下新的「Payments」元件
quiz-me                 → （選用）測試你的理解：「為什麼這個 key 需要 TTL？」
```

## 實際範例（快速路徑）

```
# "fix: wrong currency symbol in receipt total"
tdd-workflow   → 失敗測試斷言「NT$」不是「$」→ 一行修改 → 測試通過
code-reviewer  → 確認沒有其他呼叫點受影響
# 不需要 OpenSpec，不需要 archive
```

## 斜線指令（便利用）

Vendored 在 `.claude/commands/` 下：`/plan`、`/feature-dev`、`/code-review`、`/build-fix`、
`/quality-gate`、`/checkpoint`、`/learn`、`/python-review`、`/fastapi-review`。ECC 正在把 commands → skills 遷移，所以當兩者都存在時，優先用 skill；commands 保留是為了人體工學考量。
