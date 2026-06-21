# agentkit

一鍵部署的 AI 軟體開發設置，專為 **Python / FastAPI / RAG-MLOps** 專案設計。
打包四個層次成一個可部署的工具集：

| 層次 | 職責 |
|------|------|
| **原則** | 代理如何思考與修改 code（`CLAUDE.md` §1） |
| **規格層** | 動工**之前**先確認做什麼、為什麼（`openspec/`） |
| **系統文件** | 系統**目前**長什麼樣的活紀錄（`sysdoc/`） |
| **執行層** | 代理、技能、規則——*執行並驗證*工作（`.claude/`） |

設計目標：精簡、有主見、**vendored** 的子集——不是全部 ECC。它實踐自己附帶的 Simplicity-First 原則。架構細節與裁減理由見 `docs/ARCHITECTURE.md`。

## 快速開始

部署進一個專案（在專案根目錄執行）：

```bash
git clone <your-fork-of-agentkit> ~/.agentkit          # 或放任何位置
~/.agentkit/install.sh                                  # 安裝到 ./.claude + ./CLAUDE.md
```

或指定目標路徑而不切換目錄：

```bash
~/.agentkit/install.sh --target /path/to/project
```

一次安裝給機器上所有專案：

```bash
~/.agentkit/install.sh --scope global
```

選項：`--scope project|global` · `--target DIR` · `--ci` · `--no-openspec` · `--no-sysdoc` · `--force`。
重複執行是安全的（冪等）；已存在的 `CLAUDE.md` / `settings.json` / CI 檔案不會被覆蓋，除非加 `--force`。`--ci` 是 opt-in（預設關閉）——見下方說明。

**需求：** Node 20.19+（供 OpenSpec 使用）。ECC 執行層不需要額外安裝——已 vendored。

## 以 plugin 形式安裝（僅執行層）

偏好用 `/plugin`？agentkit 附帶 `.claude-plugin/` manifest，打包**執行層**——代理、技能、指令與 mentor output-style：

```text
/plugin marketplace add DancinAndrew/agnetkit
/plugin install agentkit@agentkit
```

這**不是**完整工具包：`CLAUDE.md` 契約、`.claude/rules`、permissions 與 spec/sysdoc 層因結構限制無法放進 plugin——這些請執行 `install.sh`。完整說明與 plugin vs install.sh 的選擇指南見 `docs/PLUGIN.md`。

## 你會得到什麼

- `CLAUDE.md` ——操作契約：4 原則 + 路由（spec-first vs fast-path）+ 執行迴圈 + rule imports。
- `.claude/agents/` ——14 個子代理（planner、architect、tdd-guide、code/security/python/fastapi/database/mle reviewers、build-error-resolver、refactor-cleaner、doc-updater、docs-lookup、silent-failure-hunter）。
- `.claude/skills/` ——31 個技能（tdd-workflow、search-first、verification-loop、eval-harness、fastapi/backend/api/db 模式、mle-workflow、cost-aware-llm-pipeline、continuous-learning-v2、grill-me、quiz-me、systematic-debugging、finding-duplicate-functions、skill-trigger-eval……）。
- `.claude/rules/` ——`common/`（10 條）+ `python/`（6 條）永遠載入的規則。
- `.claude/commands/` ——9 個便利斜線指令。
- `.claude/output-styles/agentkit-mentor.md` ——可切換的 mentor 模式，固化 CLAUDE.md §8（Why / Architecture note / Alternative / Worth studying + quiz-me）。已安裝但預設未啟用，需在 `/config` 選擇。（Claude Code 內建的 Explanatory/Learning 風格涵蓋一般教學需求。）
- `.claude/settings.json` ——針對 Python/FastAPI 開發迴圈調校的 allow/deny 權限模板：pytest/ruff/mypy/uv/git-write/gh/openspec 自動允許；secrets、`rm -rf`、force-push 一律擋掉。secrets 與機器特定設定放 `settings.local.json`。
- `templates/ci/` ——opt-in CI 鷹架（`--ci`）：`.pre-commit-config.yaml`（程式碼整潔 + ruff）與 uv 版 `.github/workflows/ci.yml`，內含 ruff + mypy + pytest 並設 `--cov-fail-under=80` 門檻。預設關閉——因為它會影響整個 repo，所以需要明確要求。
- `templates/statusline/` ——opt-in、零依賴 Python statusline（model · 目錄 · git branch · context% · 成本）。需手動接線，不會蓋掉既有 statusline；見 `docs/CHEATSHEET.md`。
- `openspec/` ——由 `openspec init` 鷹架建立的規格工作區。
- `sysdoc/` ——由 agentkit 鷹架建立的系統文件：`OVERVIEW.md`、`ARCHITECTURE.md`、`RUNBOOK.md`。

## 一行說完整個流程

`/opsx:propose` → 審規格 → `search-first` → `tdd-workflow`（RED/GREEN/REFACTOR）→ reviewer agents → `verification-loop` → `/opsx:archive`。小修改直接跳 TDD。完整說明：`docs/WORKFLOW.md`。

## 文件

- `docs/WORKFLOW.md` ——OpenSpec ↔ ECC 交接流程，含決策規則。
- `docs/ARCHITECTURE.md` ——層次模型與裁減理由（哪些沒放進來）。
- `docs/CHEATSHEET.md` ——技能、代理與指令快速參考。
- `docs/UPDATING.md` ——如何將 vendored ECC 子集同步到更新版本。
- `docs/HOOKS.md` ——為什麼 hooks 沒有 vendor，以及如何原生加入 ECC hooks。
- `docs/PLUGIN.md` ——透過 `/plugin` 安裝執行層，以及為什麼契約無法成為 plugin。
- `ATTRIBUTIONS.md` ——授權（ECC、Karpathy、OpenSpec——全部 MIT）。
