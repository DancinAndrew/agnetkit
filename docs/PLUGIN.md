# 以 Claude Code plugin 形式安裝 agentkit

agentkit 可以作為原生 Claude Code plugin 安裝——但**只有它的執行層**。
本頁誠實說明 plugin 給你什麼、不能給你什麼，讓你能在 `/plugin install` 和 `install.sh` 之間做出選擇。

## Plugin 附帶什麼

`.claude-plugin/` manifest 打包了**執行層**——agentkit 四個層次中，唯一對應到 Claude Code plugin 元件模型的那個層次：

- `agents/` — 14 個子代理
- `skills/` — 34 個技能
- `commands/` — 9 個斜線指令
- `output-styles/` — `agentkit Mentor` 風格

就這些。一個 `/plugin install` 讓這四個介面上線。

## Plugin **無法**附帶什麼——以及為什麼

agentkit 是一個**四層系統**（原則 → 規格 → 系統文件 → 執行）。Plugin 模型只承載最底層。上面三層在結構上超出了它能觸及的範圍：

| agentkit 層次 | 在 plugin 中？ | 為什麼不行（Claude Code plugin 規則） |
| :------------- | :------------: | :--------------------------------- |
| **`CLAUDE.md`** — 4 原則、路由、執行迴圈 | ❌ | 「plugin 根目錄的 `CLAUDE.md` 檔案**不會被載入為 project context**。」Plugin 透過技能 / 代理 / hooks 貢獻 context，不是透過永遠載入的契約。 |
| **`.claude/rules/*`** | ❌ | Rules 不是 plugin 元件類型；它們透過 `CLAUDE.md` 的 `@`-imports 載入，而 plugin 不提供這個功能。 |
| **`settings.json` permissions**（allow/deny） | ❌ | Plugin 的 `settings.json` 只支援 `agent` 和 `subagentStatusLine` keys——不支援 `permissions`。 |
| **statusline** | ❌ | 主要的 `statusLine` key 在 plugin settings 中不支援（只有 `subagentStatusLine`）。 |
| **`sysdoc/` + `openspec init`** | ❌ | 專案鷹架，不是 plugin 元件——那是 `install.sh` 的工作。 |

所以 `/plugin install agentkit` 給你工具，但**不給你契約、規則、permissions，或 spec/sysdoc 工作流程**——而那些才是讓 agentkit 成為 *agentkit* 的東西，而不只是一袋代理。把 plugin 視為執行介面的便利工具，而不是 `install.sh` 的替代品。

> 有一個已記錄的變通方案——「把指令放進技能」——但技能是在被呼叫或被認為相關時才載入的，不像 `CLAUDE.md` 契約那樣永遠載入。我們不把契約偽裝成技能；那會是包裝成同等功能的降級。

## 安裝方式

```text
/plugin marketplace add DancinAndrew/agnetkit
/plugin install agentkit@agentkit
```

然後在 `/config` 中選擇 `agentkit Mentor` output style（若你需要的話，它預設未啟用）。

在 clone 或編輯後驗證 manifest：

```bash
claude plugin validate ./payload
```

## 建議：plugin + install.sh 一起用，或只用 install.sh

- **想要完整工具包？** 執行 `install.sh`（預設路徑）。它提供全部四個層次。
- **已有自己的 `CLAUDE.md`，只想要 agentkit 的代理 / 技能 / 指令？** Plugin 適合你——安裝它，跳過其他步驟。
- **兩個都想要？** 為執行介面安裝 plugin，然後執行 `install.sh --scope project` 取得契約 / 規則 / permissions / spec / sysdoc。注意這會讓代理 / 技能 / 指令重複（一份來自 plugin cache，一份在 `.claude/`）；優先選擇一個來源以避免重複建議。
