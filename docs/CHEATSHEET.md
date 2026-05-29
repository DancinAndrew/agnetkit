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

## 標準開發流程

```
/plan "xxx"
  → /tdd-workflow  (RED → GREEN → REFACTOR)
  → code-reviewer + security-reviewer
  → /verification-loop
  → /checkpoint
  → /learn  ← 萃取可複用模式
```

**spec-first**（新功能 / 跨檔 / 碰 auth / DB schema）：

```
/opsx:propose → 審 proposal.md + design.md + tasks.md → 實作 → /opsx:archive
```

---

## sysdoc/ — 系統文件（as-built）

> `openspec/` 記錄**你打算蓋什麼**；`sysdoc/` 記錄**系統現在長什麼樣子**。

| 檔案 | 何時更新 |
|------|---------|
| `sysdoc/OVERVIEW.md` | 新增元件、改變系統邊界 |
| `sysdoc/ARCHITECTURE.md` | 做了重要架構決策（有 tradeoff 的那種）|
| `sysdoc/RUNBOOK.md` | 改了 env var、啟動步驟、部署流程 |

更新時機：每次 `/opsx:archive` 之後，確認 sysdoc 有沒有需要跟著改。
