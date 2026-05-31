# agentkit

A one-command AI software-development setup for **Python / FastAPI / RAG-MLOps** projects.
It packages four things into one deployable layer:

| Layer | Role |
|-------|------|
| **Principles** | how the agent thinks & changes code (`CLAUDE.md` §1) |
| **Spec layer** | agree on *what / why* **before** code (`openspec/`) |
| **System docs** | living record of what the system **currently** is (`sysdoc/`) |
| **Execution layer** | agents, skills, rules that *do & verify* the work (`.claude/`) |

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

Options: `--scope project|global` · `--target DIR` · `--ci` · `--no-openspec` · `--no-sysdoc` · `--force`.
Re-running is safe (idempotent); existing `CLAUDE.md` / `settings.json` / CI files are never
overwritten unless `--force`. `--ci` is opt-in (off by default) — see below.

**Requirements:** Node 20.19+ (for OpenSpec). The ECC layer needs nothing — it's vendored.

## What you get

- `CLAUDE.md` — the operating contract: 4 principles + routing (spec-first vs fast-path)
  + the execution loop + rule imports.
- `.claude/agents/` — 14 subagents (planner, architect, tdd-guide, code/security/python/
  fastapi/database/mle reviewers, build-error-resolver, refactor-cleaner, doc-updater,
  docs-lookup, silent-failure-hunter).
- `.claude/skills/` — 28 skills (tdd-workflow, search-first, verification-loop,
  eval-harness, fastapi/backend/api/db patterns, mle-workflow, cost-aware-llm-pipeline,
  continuous-learning-v2, grill-me, quiz-me, …).
- `.claude/rules/` — `common/` (10) + `python/` (6) always-follow rules.
- `.claude/commands/` — 9 convenience slash entries.
- `.claude/settings.json` — a permission allow/deny template tuned to the Python/FastAPI
  inner loop: pytest/ruff/mypy/uv/git-write/gh/openspec auto-allowed; secrets, `rm -rf`,
  and force-push denied. Secrets and machine-specific overrides go in `settings.local.json`.
- `templates/ci/` — opt-in CI scaffolding (`--ci`): a `.pre-commit-config.yaml` (hygiene +
  ruff) and a uv-based `.github/workflows/ci.yml` that runs ruff + mypy + pytest with an
  `--cov-fail-under=80` gate. Off by default — it shapes the whole repo, so you ask for it.
- `openspec/` — spec workspace scaffolded by `openspec init`.
- `sysdoc/` — system documentation scaffolded by agentkit: `OVERVIEW.md`, `ARCHITECTURE.md`, `RUNBOOK.md`.

## The workflow in one line

`/opsx:propose` → review spec → `search-first` → `tdd-workflow` (RED/GREEN/REFACTOR) →
reviewer agents → `verification-loop` → `/opsx:archive`. Small fixes skip straight to TDD.
Full detail: `docs/WORKFLOW.md`.

## Docs

- `docs/WORKFLOW.md` — the OpenSpec ↔ ECC handoff, with the decision rule.
- `docs/ARCHITECTURE.md` — the layer model and the curation rationale (what was cut).
- `docs/CHEATSHEET.md` — skills, agents, and commands quick reference.
- `docs/UPDATING.md` — how to re-sync the vendored ECC subset to a newer commit.
- `docs/HOOKS.md` — why hooks aren't vendored, and how to add ECC's natively if you want them.
- `ATTRIBUTIONS.md` — licenses (ECC, Karpathy, OpenSpec — all MIT).
