# Workflow: OpenSpec ↔ ECC handoff

agentkit runs two systems in sequence. OpenSpec owns **what/why** (the spec). ECC owns
**how** (execution + verification). The Karpathy principles in `CLAUDE.md` govern both.

```
            ┌─────────────────────────────────────────────────────────┐
            │  Is this change non-trivial? (see decision rule below)    │
            └───────────────┬───────────────────────────┬─────────────┘
                       yes  │                       no   │
                            ▼                            ▼
                   ┌─────────────────┐          ┌──────────────────┐
                   │  OpenSpec lane  │          │  Fast-path lane  │
                   └────────┬────────┘          └────────┬─────────┘
   /opsx:propose "<idea>"   │                            │
   → proposal.md            │                            │
   → design.md              │                            │
   → tasks.md               │                            │
   review with human  ◀─────┘                            │
                            │                            │
                            ▼                            ▼
                   ════════════ ECC execution loop (per task) ════════════
                   1. search-first   (research before code)
                   2. tdd-workflow   (RED → GREEN → REFACTOR, ≥80% changed-line cov)
                   3. reviewer agents (code / security / python / fastapi / mle / db)
                   4. verification-loop / eval-harness (loop until criteria met)
                   ══════════════════════════════════════════════════════
                            │
                            ▼
                   /opsx:archive   (spec-first lane only — fold specs back)
```

## Decision rule — which lane?

Go **OpenSpec (spec-first)** if *any* is true:
- new feature or module;
- requirements ambiguous or multiple valid interpretations;
- touches **auth, payments, money, or the data model / migrations**;
- spans multiple files or services;
- changes externally observable behavior.

Otherwise **fast-path**: typos, comments, formatting, one-line fixes, obviously-scoped
local changes. If behavior changes, still write the failing test first.

> Tie-breaker: unsure → spec-first. Cheap insurance against building the wrong thing.

## Why this split (the trade-off)

Both OpenSpec and ECC have a "planning" surface, so without a rule they overlap and you
plan twice. The clean seam:

- **OpenSpec = problem definition.** `proposal.md` (why), `specs/` (requirements +
  scenarios), `design.md` (technical approach), `tasks.md` (checklist). This is the
  artifact a reviewer (or future-you) reads to understand intent. It is also the FDE /
  consultant muscle: a paper trail of *what was agreed*.
- **ECC = implementation.** Its `planner`/`architect` agents turn an *approved* task into
  code structure; `tdd-guide` enforces tests-first; reviewer agents catch defects. ECC
  does not decide *whether* to build — OpenSpec already settled that.

Hand-off point: **`tasks.md` is the contract.** OpenSpec produces it; ECC consumes it one
item at a time. Don't let ECC re-open scope questions that belong in the proposal, and
don't let OpenSpec specify implementation detail that belongs in TDD.

## Worked example (spec-first)

```
/opsx:propose "add idempotent ticket purchase endpoint"
  → review proposal.md (why: double-charge bug), design.md (idempotency key in Redis),
    tasks.md (1. schema, 2. endpoint, 3. concurrency test, 4. docs)

# task 1
search-first            → read existing payment + schema code, confirm Redis is available
tdd-workflow            → failing migration test → minimal migration → refactor
database-reviewer       → check the migration + query plan

# task 2..3
tdd-workflow            → failing concurrency test (two parallel buys, one charge) → impl
security-reviewer       → auth + replay-attack check on the idempotency key
fastapi-reviewer        → endpoint contract, status codes, error shape
verification-loop       → all tasks' success criteria green

/opsx:archive           → specs folded back; ready for next change
```

## Worked example (fast-path)

```
# "fix: wrong currency symbol in receipt total"
tdd-workflow   → failing test asserts "NT$" not "$" → one-line fix → test green
code-reviewer  → confirm no other call sites affected
# no OpenSpec, no archive
```

## Slash commands (convenience)

Vendored under `.claude/commands/`: `/plan`, `/feature-dev`, `/code-review`, `/build-fix`,
`/quality-gate`, `/checkpoint`, `/learn`, `/python-review`, `/fastapi-review`. ECC is
migrating commands → skills, so prefer the skill when both exist; commands are kept for
ergonomics.
