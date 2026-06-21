# 架構與裁減理由

## 層次模型

```
┌──────────────────────────────────────────────────────────────┐
│ 原則  —  CLAUDE.md §1（Karpathy 4 原則）                       │  管轄所有層次
├──────────────────────────────────────────────────────────────┤
│ 規格層  —  OpenSpec（openspec/）                                │  做什麼、為什麼
├──────────────────────────────────────────────────────────────┤
│ 執行層  —  ECC 子集（.claude/agents|skills|rules|cmds）          │  怎麼做、如何驗證
└──────────────────────────────────────────────────────────────┘
```

為什麼是三層而不是一個合併的超大檔案：單一串接的 `CLAUDE.md` 是來源文件警告的失敗模式——它會讓永遠載入的 context 膨脹，也與 ECC 自身的 token 優化設計衝突。依*各層次何時需要*來分割，可讓永遠載入預算保持精簡（原則 + 少數規則），同時讓代理 / 技能依需求載入。

## 從 ECC 裁選了什麼，以及為什麼

ECC 附帶約 60 個代理、約 180 個技能，以及 TS/Go/Rust/Swift/Java/PHP/Perl/ArkTS/C++/C#/Dart/Ruby/Kotlin/React/Angular/Vue 的語言包。全部 vendor 進來會：
- 讓永遠載入規則預算爆炸，
- 讓技能 / 代理建議空間充斥無關條目，以及
- 違反本工具包附帶的 Simplicity-First 原則。

因此 agentkit 只 vendor 了 **Python / FastAPI / RAG-MLOps** 切片。

### 保留的代理（14 個）
`planner`、`architect`、`tdd-guide`、`code-reviewer`、`security-reviewer`、
`python-reviewer`、`fastapi-reviewer`、`database-reviewer`、`mle-reviewer`、
`build-error-resolver`、`refactor-cleaner`、`doc-updater`、`docs-lookup`、
`silent-failure-hunter`。

### 保留的技能（34 個）
工作流程：`tdd-workflow`、`search-first`、`security-review`、`verification-loop`、
`eval-harness`、`continuous-learning-v2`、`deep-research`、`iterative-retrieval`、
`context-budget`、`error-handling`、`git-workflow`、`architecture-decision-records`。
Python / 後端：`python-patterns`、`python-testing`、`fastapi-patterns`、
`backend-patterns`、`api-design`、`database-migrations`、`postgres-patterns`、
`docker-patterns`、`deployment-patterns`。
RAG/LLM/ML：`mle-workflow`、`cost-aware-llm-pipeline`、`regex-vs-llm-structured-text`、
`mcp-server-patterns`、`content-hash-cache-pattern`。
學習：`grill-me`、`quiz-me`。
除錯 / 品質（**非 ECC**——移植自 obra/superpowers（MIT），及 agentkit 原創）：`systematic-debugging`、`finding-duplicate-functions`、`skill-trigger-eval`。
規格 / 流程（**非 ECC**——agentkit 原創，源自 Loop Engineering SOP 與 DDD）：`ubiquitous-language`、`post-mortem`、`adversarial-spec-review`。

### 保留的規則
`rules/common/`（全部 10 條）+ `rules/python/`（全部 6 條，包含 `fastapi.md`）。沒有其他語言包。

### 明確未 vendor 的項目
- **所有非 Python 語言包**（TS/Go/Rust/Swift/Java……）。若專案需要，之後再加——見 `docs/UPDATING.md`。
- **Hook 執行期。** 它與 ECC 的原生 plugin 安裝布局耦合，並拉入大量腳本樹（`sql.js`、`ajv`、dispatchers、plugin-root resolver）。獨立 vendor 會很脆弱且臃腫。見 `docs/HOOKS.md`。
- **與後端 / RAG 無關的 domain 技能**（內容 / 行銷 / 影片 / 財務 / homelab / 網路 / 醫療 / iOS / Android 等）。

## 去重複：Karpathy 原則 vs ECC 規則

Karpathy 原則與 `rules/common` 的部分內容重疊（coding-style、patterns、development-workflow）。與其從 ECC 的檔案中刪除（這會讓重新同步很麻煩），本工具包把它們定位為**兩個層次，在不同範疇載入**：

- `CLAUDE.md §1` = 簡短的永遠載入**原則**（契約）。
- `rules/*` = 詳細的**操作說明**，選擇性匯入。

`CLAUDE.md §5` 只匯入 8 個永遠載入的規則檔案；其餘放在 `.claude/rules/` 供依需求參考。若你覺得重複太多，修剪 §5 匯入清單——那個清單*就是*你的永遠載入 context 預算。這是調整 context 成本最大的旋鈕。

## 實際上各層次是怎麼載入的（per harness）

- `CLAUDE.md` — 由 Claude Code 自動載入；`@`-imports 把規則檔案拉進來。
- `.claude/agents/*.md` — 被發現為子代理。
- `.claude/skills/*/SKILL.md` — 被發現為技能（呼叫或建議時載入）。
- `.claude/commands/*.md` — 被發現為斜線指令。
- `.claude/contexts/*.md` — 手動：想要 dev/review/research 模式時貼上或參考。
- `.claude/mcp-configs/mcp-servers.json` — 參考用；需手動接入你的 MCP client。
- `.claude/settings.json` — 由 Claude Code 自動載入；它的 `permissions.allow/deny` 規則由 harness 強制執行（不靠 model），所以它用真實邊界支撐了 `rules/common/security.md` 中的散文規則。重跑 `install.sh` 永遠不會覆蓋已存在的 settings.json——它會另外寫一個 `settings.json.agentkit` 讓你合併（`--force` 才覆蓋）。Secrets 放 `settings.local.json`。

若 harness 不支援 `@`-imports，規則仍存在於磁碟上作為參考，可以明確指向它們。
