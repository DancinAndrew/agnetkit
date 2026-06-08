# 更新 vendored 的 ECC 子集

`payload/.claude/` 中的 ECC 切片固定在 `VERSION` 中的 commit。要在不重新引入 bloat 的情況下拉入更新的 ECC，對新的 clone 重新執行裁選。

## 重新同步步驟

```bash
# 1. clone 你要的版本
git clone https://github.com/affaan-m/ECC.git /tmp/ECC
cd /tmp/ECC && git rev-parse HEAD          # 記下這個 hash，要更新到 VERSION

# 2. 從你的 agentkit repo 根目錄：
AK="$(pwd)"          # agentkit repo
SRC=/tmp/ECC

# 3. 重新複製已裁選的清單（這些就是裁選——在這裡編輯來改變範疇）
AGENTS="planner architect tdd-guide code-reviewer security-reviewer python-reviewer \
fastapi-reviewer database-reviewer mle-reviewer build-error-resolver refactor-cleaner \
doc-updater docs-lookup silent-failure-hunter"

SKILLS="tdd-workflow search-first security-review verification-loop eval-harness \
continuous-learning-v2 deep-research iterative-retrieval context-budget error-handling \
git-workflow python-patterns python-testing fastapi-patterns backend-patterns api-design \
database-migrations postgres-patterns docker-patterns deployment-patterns mle-workflow \
cost-aware-llm-pipeline regex-vs-llm-structured-text mcp-server-patterns \
content-hash-cache-pattern architecture-decision-records"

CMDS="plan feature-dev code-review build-fix quality-gate checkpoint learn python-review \
fastapi-review"

for a in $AGENTS; do cp "$SRC/agents/$a.md" "$AK/payload/.claude/agents/"; done
for s in $SKILLS; do rm -rf "$AK/payload/.claude/skills/$s"; cp -R "$SRC/skills/$s" "$AK/payload/.claude/skills/"; done
for c in $CMDS;   do cp "$SRC/commands/$c.md" "$AK/payload/.claude/commands/"; done
rm -rf "$AK/payload/.claude/rules/common" "$AK/payload/.claude/rules/python"
cp -R "$SRC/rules/common" "$SRC/rules/python" "$AK/payload/.claude/rules/"
cp "$SRC/contexts/dev.md" "$SRC/contexts/review.md" "$SRC/contexts/research.md" "$AK/payload/.claude/contexts/"
cp "$SRC/mcp-configs/mcp-servers.json" "$AK/payload/.claude/mcp-configs/"
cp "$SRC/LICENSE" "$AK/ECC-LICENSE"

# 4. 在 VERSION 中更新 commit + 日期，commit，完成。
```

## 事後加入語言包

若某個專案需要 TypeScript，例如：

```bash
cp -R /tmp/ECC/rules/typescript "$AK/payload/.claude/rules/"
cp /tmp/ECC/agents/typescript-reviewer.md "$AK/payload/.claude/agents/"
# 加入相關技能，然後若要永遠載入，在 CLAUDE.md §5 匯入新規則。
```

謹慎地加入。你加入的每條永遠載入規則都是每個 session 永久的 context 成本——這正是裁選存在要管理的 tradeoff。

## 同步後的健全性檢查

```bash
ls payload/.claude/agents | wc -l        # 預期你的代理數量
find payload/.claude/skills -name SKILL.md | wc -l   # 每個技能一個
bash -n install.sh                       # 安裝腳本仍可解析
```
