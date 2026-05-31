# agentkit — Claude Code 備忘錄

## Slash Commands（`/`）

| 指令 | 用途 |
|------|------|
| `/plan "feature"` | 列出風險 + 逐步實作計畫，**等你確認才動 code** |
| `/feature-dev` | 先讀懂現有 code 再開發新功能的引導流程 |
| `/tdd-workflow` | RED→GREEN→REFACTOR，目標 ≥80% coverage |
| `/code-review [PR# \| URL]` | 審查本地未提交變更，或指定 GitHub PR |
| `/python-review` | PEP8、type hints、Pythonic idioms 全套審查 |
| `/fastapi-review` | async 正確性、Pydantic、DI、security、testability |
| `/quality-gate` | 跑完整 ECC 品質 pipeline，輸出修復清單 |
| `/build-fix` | 偵測 build 系統，增量修 build/type errors |
| `/checkpoint` | 建立/列出 workflow 驗証節點 |
| `/learn` | 把當前 session 的模式萃取成 candidate skills |

---

## Skills（情境觸發）

### 開發流程

| Skill | 何時用 |
|-------|--------|
| `search-first` | 寫 code 前，先搜尋既有工具和 library |
| `tdd-workflow` | 新功能、bug fix、重構 |
| `verification-loop` | 驗証成功標準，loop 直到全綠 |
| `eval-harness` | eval-driven development 正式評估框架 |
| `context-budget` | context 視窗吃太多時，找出 bloat |
| `continuous-learning-v2` | session 觀察 → 產生 instincts → 演化成新 skills |

### 架構 & 設計

| Skill | 何時用 |
|-------|--------|
| `api-design` | REST 資源命名、pagination、versioning |
| `backend-patterns` | Node/Express/Next.js 後端架構 |
| `fastapi-patterns` | FastAPI async、DI、Pydantic、OpenAPI |
| `architecture-decision-records` | 自動偵測架構決策時機，寫成 ADR |
| `iterative-retrieval` | subagent context 不足時的漸進式 retrieval |
| `regex-vs-llm-structured-text` | 決定要用 regex 還是 LLM 解析文字 |

### 資料庫

| Skill | 何時用 |
|-------|--------|
| `database-migrations` | schema 變更、zero-downtime migration、rollback |
| `postgres-patterns` | query 優化、index、schema 設計（Supabase） |

### 基礎設施

| Skill | 何時用 |
|-------|--------|
| `docker-patterns` | 本地 dev、container security、multi-service |
| `deployment-patterns` | CI/CD、health check、rollback、上線 checklist |
| `mcp-server-patterns` | 用 Node/TS SDK 建 MCP server |
| `git-workflow` | branching strategy、commit 慣例、conflict |

### Python 專屬

| Skill | 何時用 |
|-------|--------|
| `python-patterns` | Pythonic idioms、PEP8、type hints |
| `python-testing` | pytest、fixtures、mock、parametrize |

### AI / MLOps

| Skill | 何時用 |
|-------|--------|
| `mle-workflow` | ML 訓練、評估、serving、監控、rollback |
| `cost-aware-llm-pipeline` | LLM 成本優化、model routing、prompt caching |
| `content-hash-cache-pattern` | 用 SHA-256 cache 昂貴的檔案處理結果 |

### 學習 & 拷問（grill 雙人組）

| Skill | 何時用 |
|-------|--------|
| `grill-me` | **寫 code 前** 拷問你的設計，一次一題逼到零模糊，再餵給 `/plan`、OpenSpec |
| `quiz-me` | **學習時** 蘇格拉底式考你對某段 code/概念的理解，只問不答，找出你的盲點 |

> 口訣：`grill-me` 問你的**計畫**、`quiz-me` 問你的**理解**——開發迴圈的兩端。

### 其他

| Skill | 何時用 |
|-------|--------|
| `security-review` | 碰 auth、user input、secrets、API、付款 |
| `error-handling` | typed errors、retry、circuit breaker（TS/Python/Go）|
| `deep-research` | 多來源網路研究 + 引用報告（需 firecrawl/exa MCP）|
| `context-budget` | 審計 context 消耗，找 token 節省點 |

---

## Agents（自動委派）

| Agent | 觸發時機 |
|-------|---------|
| `planner` | 複雜功能、架構變更 |
| `architect` | 系統設計、scalability 決策 |
| `tdd-guide` | 寫新功能 / fix bug |
| `code-reviewer` | **每次改完 code 都要跑** |
| `security-reviewer` | 碰 auth、input、PII、外部 API |
| `python-reviewer` | 所有 Python 改動 |
| `fastapi-reviewer` | FastAPI 路由、schema、middleware |
| `database-reviewer` | SQL、migration、schema 設計 |
| `mle-reviewer` | ML pipeline、feature store、inference |
| `build-error-resolver` | build 炸了、type error |
| `refactor-cleaner` | 清 dead code（knip/depcheck/ts-prune）|
| `silent-failure-hunter` | 加 error handling、碰 async/IO |
| `doc-updater` | 更新 README、codemap |
| `docs-lookup` | 問 library/framework API 用法 |

---

## 標準開發流程（整合版）

照這棵決策樹走，不用每次煩惱用哪個工具：

```
0a. 【每次開新 session 先做這個】
    說「繼續」「上次做到哪」「接著做」
    → Claude 讀 .agent-memory.md，摘要上次進度給你

0b. 想法在你腦袋裡還很糊？
   → grill-me            (一次一題逼到零模糊，選用)
        │
1. 這個改動多大？
   ├── 大 (新功能 / 碰 auth,money,DB / 跨檔 / 改外部行為) ── spec-first
   │      → /opsx:propose → 審 proposal+design+tasks.md → 跟人對齊
   │        (tasks.md 就是你的 plan，不要再 /plan)
   │
   └── 小 (typo / 一行 / 明確的局部改) ─────────────────── fast-path
          → /plan (想要步驟就用) 或直接跳下一步
        │
2. ══ 每個 task 跑這個迴圈 ══
   search-first          (動手前先查既有方案)
   → /tdd-workflow       (RED：把 spec scenario 寫成失敗測試 → GREEN → REFACTOR)
   → code-reviewer + security-reviewer (+ python/fastapi/db/mle 看情況)
   → /verification-loop  (loop 到成功標準全綠)
   → /checkpoint         (寫進 .agent-memory.md)
        │
3. update sysdoc/        (系統形狀變了才要)
        │
4. /opsx:archive         (只有 spec-first 要，把 spec 收回對帳)
        │
5. quiz-me               (考自己懂不懂剛做的東西，選用——學習用)
   /learn                (萃取可複用 pattern，選用)
```

### 心法三條（背這個就好）

1. **腦袋糊 → `grill-me`**（任何 lane 都可先做）
2. **大改動 → `/opsx:propose`；小改動 → `/plan`。二選一，不要兩個都跑**
3. **RED 測試從 spec 的 scenario 來** ← 這就是防止「實作跟 spec 跑掉」的機制

### grill-me / /plan / /opsx:propose 到底差在哪

| 工具 | 做什麼 | 產出 | 何時 |
|------|--------|------|------|
| `grill-me` | 逼出你腦袋裡模糊的想法 | 想清楚（summary） | 自己都還沒想清楚 |
| `/opsx:propose` | 寫成正式契約 | proposal/design/tasks.md（存檔、archive） | 大改動 |
| `/plan` | 快速列實作步驟 + 風險 | 對話裡的 checklist（不存檔） | 小到中改動 |

> `/plan` 和 `/opsx:propose` 是**同一件事的輕重版**，二選一。`grill-me` 在它們**之前**，是前置不是替代。

---

## 跨 session 記憶

Claude 預設沒有跨 session 記憶。用這個約定補上：

| 動作 | 效果 |
|------|------|
| 說「收工」「先這樣」「結束」 | Claude 把進度寫進 `.agent-memory.md` |
| 說「繼續」「上次做到哪」 | Claude 讀取最後一筆記錄，摘要給你聽 |
| `/checkpoint` | 也會觸發寫入 |

`.agent-memory.md` 在 git-ignored，是你個人的，不會進 repo。

---

## sysdoc/ — 系統文件（as-built）

> `openspec/` 記錄**你打算蓋什麼**；`sysdoc/` 記錄**系統現在長什麼樣子**。

| 檔案 | 何時更新 |
|------|---------|
| `sysdoc/OVERVIEW.md` | 新增元件、改變系統邊界 |
| `sysdoc/ARCHITECTURE.md` | 做了重要架構決策（有 tradeoff 的那種）|
| `sysdoc/RUNBOOK.md` | 改了 env var、啟動步驟、部署流程 |

更新時機：每次 `/opsx:archive` 之後，確認 sysdoc 有沒有需要跟著改。
