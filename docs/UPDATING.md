# Updating the vendored ECC subset

The ECC slice in `payload/.claude/` is pinned to the commit in `VERSION`. To pull a newer
ECC without re-adding the bloat, re-run the curation against a fresh clone.

## Re-sync recipe

```bash
# 1. clone the version you want
git clone https://github.com/affaan-m/ECC.git /tmp/ECC
cd /tmp/ECC && git rev-parse HEAD          # note this hash for VERSION

# 2. from your agentkit repo root:
AK="$(pwd)"          # agentkit repo
SRC=/tmp/ECC

# 3. re-copy the curated lists (these ARE the curation — edit here to change scope)
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

# 4. bump the commit + date in VERSION, commit, done.
```

## Adding a language pack later

If a project needs, say, TypeScript:

```bash
cp -R /tmp/ECC/rules/typescript "$AK/payload/.claude/rules/"
cp /tmp/ECC/agents/typescript-reviewer.md "$AK/payload/.claude/agents/"
# add the relevant skills, then import the new rules in CLAUDE.md §5 if they should be always-on.
```

Keep additions deliberate. Every always-on rule you add is permanent context cost on every
session — that is exactly the trade-off the curation exists to manage.

## Sanity check after a sync

```bash
ls payload/.claude/agents | wc -l        # expect your agent count
find payload/.claude/skills -name SKILL.md | wc -l   # one per skill
bash -n install.sh                       # installer still parses
```
