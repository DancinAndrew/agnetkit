# agentkit

A one-command AI software-development setup for **Python / FastAPI / RAG-MLOps** projects.
It packages three things into one deployable layer:

| Layer | Source | Role |
|-------|--------|------|
| **Principles** | Karpathy 4 principles | how the agent thinks & changes code (`CLAUDE.md` §1) |
| **Spec layer** | OpenSpec | agree on *what / why* before code (`openspec/`) |
| **Execution layer** | curated ECC subset | agents, skills, rules that *do & verify* the work (`.claude/`) |

Design goal: a small, opinionated, **vendored** subset — not all of ECC. It practices the
Simplicity-First principle it ships with. See `docs/ARCHITECTURE.md` for what was cut and why.

## Quick start

Deploy into a project (run from the project root):

```bash
git clone <your-fork-of-agentkit> ~/.agentkit          # or keep it anywhere
~/.agentkit/install.sh                                  # installs into ./.claude + ./CLAUDE.md
```

Or point it at a target without cd-ing:

```bash
~/.agentkit/install.sh --target /path/to/project
```

Install once for every project on the machine instead:

```bash
~/.agentkit/install.sh --scope global
```

Options: `--scope project|global` · `--target DIR` · `--no-openspec` · `--force`.
Re-running is safe (idempotent); an existing `CLAUDE.md` is never overwritten unless `--force`.

**Requirements:** Node 20.19+ (for OpenSpec). The ECC layer needs nothing — it's vendored.

## What you get

- `CLAUDE.md` — the operating contract: 4 principles + routing (spec-first vs fast-path)
  + the execution loop + rule imports.
- `.claude/agents/` — 14 subagents (planner, architect, tdd-guide, code/security/python/
  fastapi/database/mle reviewers, build-error-resolver, refactor-cleaner, doc-updater,
  docs-lookup, silent-failure-hunter).
- `.claude/skills/` — 26 skills (tdd-workflow, search-first, verification-loop,
  eval-harness, fastapi/backend/api/db patterns, mle-workflow, cost-aware-llm-pipeline,
  continuous-learning-v2, …).
- `.claude/rules/` — `common/` (10) + `python/` (6) always-follow rules.
- `.claude/commands/` — 9 convenience slash entries.
- `openspec/` — spec workspace scaffolded by `openspec init`.

## The workflow in one line

`/opsx:propose` → review spec → `search-first` → `tdd-workflow` (RED/GREEN/REFACTOR) →
reviewer agents → `verification-loop` → `/opsx:archive`. Small fixes skip straight to TDD.
Full detail: `docs/WORKFLOW.md`.

## Docs

- `docs/WORKFLOW.md` — the OpenSpec ↔ ECC handoff, with the decision rule.
- `docs/ARCHITECTURE.md` — the layer model and the curation rationale (what was cut).
- `docs/UPDATING.md` — how to re-sync the vendored ECC subset to a newer commit.
- `docs/HOOKS.md` — why hooks aren't vendored, and how to add ECC's natively if you want them.
- `ATTRIBUTIONS.md` — licenses (ECC, Karpathy, OpenSpec — all MIT).
