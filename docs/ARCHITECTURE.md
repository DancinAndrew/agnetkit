# Architecture & curation rationale

## The layer model

```
┌──────────────────────────────────────────────────────────────┐
│ Principles  —  CLAUDE.md §1  (Karpathy 4 principles)           │  governs everything
├──────────────────────────────────────────────────────────────┤
│ Spec layer  —  OpenSpec (openspec/)                            │  what & why
├──────────────────────────────────────────────────────────────┤
│ Execution   —  ECC subset (.claude/agents|skills|rules|cmds)   │  how & verify
└──────────────────────────────────────────────────────────────┘
```

Why three layers instead of one merged mega-file: a single concatenated `CLAUDE.md` is
the failure mode the sources warn about — it bloats always-on context and fights ECC's own
token-optimization design. Splitting by *when each thing is needed* keeps the always-on
budget small (principles + a few rules) while agents/skills load on demand.

## What was curated from ECC, and why

ECC ships ~60 agents, ~180 skills, and language packs for TS/Go/Rust/Swift/Java/PHP/Perl/
ArkTS/C++/C#/Dart/Ruby/Kotlin/React/Angular/Vue. Vendoring all of it would:
- blow the always-on rule budget,
- fill skill/agent suggestion space with irrelevant entries, and
- violate Simplicity-First (the principle this kit ships with).

So agentkit vendors a **Python / FastAPI / RAG-MLOps** slice only.

### Agents kept (14)
`planner`, `architect`, `tdd-guide`, `code-reviewer`, `security-reviewer`,
`python-reviewer`, `fastapi-reviewer`, `database-reviewer`, `mle-reviewer`,
`build-error-resolver`, `refactor-cleaner`, `doc-updater`, `docs-lookup`,
`silent-failure-hunter`.

### Skills kept (28)
Workflow: `tdd-workflow`, `search-first`, `security-review`, `verification-loop`,
`eval-harness`, `continuous-learning-v2`, `deep-research`, `iterative-retrieval`,
`context-budget`, `error-handling`, `git-workflow`, `architecture-decision-records`.
Python/backend: `python-patterns`, `python-testing`, `fastapi-patterns`,
`backend-patterns`, `api-design`, `database-migrations`, `postgres-patterns`,
`docker-patterns`, `deployment-patterns`.
RAG/LLM/ML: `mle-workflow`, `cost-aware-llm-pipeline`, `regex-vs-llm-structured-text`,
`mcp-server-patterns`, `content-hash-cache-pattern`.
Learning: `grill-me`, `quiz-me`.

### Rules kept
`rules/common/` (all 10) + `rules/python/` (all 6, incl. `fastapi.md`). No other language
packs.

### Explicitly NOT vendored
- **All non-Python language packs** (TS/Go/Rust/Swift/Java/…). Add later if a project needs
  one — see `docs/UPDATING.md`.
- **Hook runtime.** It is coupled to ECC's native plugin-install layout and pulls in a
  large script tree (`sql.js`, `ajv`, dispatchers, plugin-root resolver). Standalone
  vendoring would be fragile and bloated. See `docs/HOOKS.md`.
- **Domain skills** unrelated to backend/RAG (content/marketing/video/finance-ops/homelab/
  networking/healthcare/iOS/Android/etc.).

## De-duplication: Karpathy vs ECC rules

The Karpathy principles overlap with parts of `rules/common` (coding-style, patterns,
development-workflow). Rather than delete from ECC's files (which would make re-syncing
painful), the kit positions them as **two layers, loaded at different scopes**:

- `CLAUDE.md §1` = the short, always-on **principles** (the contract).
- `rules/*` = the detailed **operational elaboration**, imported selectively.

`CLAUDE.md §5` imports only 8 always-on rule files; the rest stay in `.claude/rules/` for
on-demand reference. If you find duplication too heavy, trim the §5 import list — that list
*is* your always-on context budget. This is the single biggest knob for context cost.

## How things actually load (per harness)

- `CLAUDE.md` — auto-loaded by Claude Code; `@`-imports pull in the rule files.
- `.claude/agents/*.md` — discovered as subagents.
- `.claude/skills/*/SKILL.md` — discovered as skills (loaded when invoked/suggested).
- `.claude/commands/*.md` — discovered as slash commands.
- `.claude/contexts/*.md` — manual: paste/reference when you want a dev/review/research mode.
- `.claude/mcp-configs/mcp-servers.json` — reference; wire into your MCP client manually.
- `.claude/settings.json` — auto-loaded by Claude Code; its `permissions.allow/deny` rules
  are enforced by the harness (not the model), so they back the prose in `rules/common/
  security.md` with an actual boundary. Re-running `install.sh` never clobbers an existing
  one — it writes `settings.json.agentkit` for you to merge. Secrets → `settings.local.json`.

If a harness doesn't support `@`-imports, the rules still live on disk as reference and can
be pointed at explicitly.
