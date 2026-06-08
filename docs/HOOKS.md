# Hooks：為什麼沒有 vendor

原本的計畫是把 ECC 的 `memory-persistence` 和 `strategic-compact` hooks 作為 opt-in 附加品一起 vendor。實際查看 code 之後，發現這個決定是錯的。以下是誠實的推理過程，讓你自己判斷。

## 我發現了什麼

ECC 的 production hook 圖（`hooks/hooks.json`）**與 ECC 的原生 plugin 安裝布局耦合**：

- 每個 hook 指令都是一個 inline 的 `node -e "..."` **plugin-root resolver**，用來尋找 `~/.claude/plugins/ecc/...`、`~/.claude/plugins/cache/ecc/<org>/<version>/...` 等路徑。
- SessionStart hook（`session-start-bootstrap.js`）**自己不做任何事**——它解析 plugin root，然後 spawn `run-with-flags.js → session-start.js`，並由 hook-profile/flags 系統把關。
- 有狀態的部件（`session-manager.js`、`state-store/`）拉入了 native-ish 依賴（`sql.js`、`ajv`）以及龐大的 `scripts/lib/` 樹。

唯一真正獨立的腳本是 `pre-compact.js`（一個 compaction logger）。但一個沒有能運作的 SessionStart **loader** 的「compaction 時儲存狀態」hook 是半個系統——它寫了沒人會讀回來的 context。不值得。

## 決策

獨立 vendor 這個東西意味著要複製一大堆緊耦合的腳本樹，然後重寫它的路徑解析——很脆弱，且直接違反本工具包核心的 Simplicity-First 原則。所以：

- **agentkit 不附帶 hooks。** 這也符合低 context / 本機模型友好的預設設定。
- 如果你想要 ECC 的 hooks，用**它們被設計的安裝方式**：以原生 plugin 安裝。

## 如何原生加入 ECC hooks（選用）

Hooks 是 ECC 中最適合從 ECC 本身取得的部分。在 Claude Code 中：

```
/plugin marketplace add https://github.com/affaan-m/ECC
/plugin install ecc@ecc
```

這會給你 ECC 的 hooks（記憶持久化、strategic compaction、continuous-learning 訊號），並附帶完整的 resolver 和腳本樹。

> 共存注意事項：ECC plugin 也附帶代理 / 技能 / 指令，與 agentkit vendored 的副本有重疊。為了避免重複的建議介面，若你為了 hooks 安裝了完整 ECC plugin，考慮從你的專案 `.claude/` 移除重疊的 vendored 副本（或反之亦然）。不要同時跑 plugin **和** ECC 的 `install.sh --profile full`——那個雙重安裝是 ECC 最常見的 breakage。

## 一個最小的自製記憶 hook（opt-in，以 template 形式附帶）

agentkit 附帶一個小型、零依賴的 hook 作為 **template**——不預設接線，因為 hooks 保持 opt-in：`payload/templates/memory-hook/agentkit-memory-start.sh`。這是一個 `SessionStart` hook，它會把最近的 `.agent-memory.md` 條目注入 context，讓新 session 一開始就知道你上次做到哪了——不需要輸入「繼續」。

> **為什麼只有 SessionStart（讀取端）？** `SessionEnd` hook *無法*寫入有用的摘要：它是一個普通腳本，接收的是原始 transcript 路徑，而摘要一段對話需要的是 model，不是 `awk`。Claude Code 文件也說明 SessionEnd hooks 無法添加 context。所以**寫入**留在它本來應該在的地方——交給 Claude，在「收工」/ `/checkpoint` 時（CLAUDE.md §7）。Hook 只自動化**讀取**，這是腳本做得到的事。

### 接線方式（per 專案）

1. 把腳本複製到專案並設為可執行：
   ```bash
   mkdir -p .claude/hooks
   cp ~/.agentkit/payload/templates/memory-hook/agentkit-memory-start.sh .claude/hooks/
   chmod +x .claude/hooks/agentkit-memory-start.sh
   ```
2. 註冊它——把以下內容加到 `.claude/settings.json`（已 commit、全團隊）或
   `.claude/settings.local.json`（個人，對應 `.agent-memory.md` 的 git-ignored 狀態）：
   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "matcher": "startup|resume",
           "hooks": [
             { "type": "command",
               "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/agentkit-memory-start.sh" }
           ]
         }
       ]
     }
   }
   ```
   若 `hooks` key 已存在，合併 `SessionStart` 陣列而不是覆蓋。

就這樣——約 12 行 bash，不需要 Node，不需要依賴，不需要 plugin resolver。
