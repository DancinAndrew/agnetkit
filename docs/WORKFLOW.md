# Workflow: OpenSpec ↔ ECC handoff

agentkit runs two systems in sequence. OpenSpec owns **what/why** (the spec). ECC owns
**how** (execution + verification). The Karpathy principles in `CLAUDE.md` govern both.

```
            ┌─────────────────────────────────────────────────────────┐
            │  Is the idea still fuzzy in YOUR head?                    │
            │  yes → grill-me  (interview to zero ambiguity)  [opt]     │
            └───────────────────────────┬─────────────────────────────┘
                                        ▼
            ┌─────────────────────────────────────────────────────────┐
            │  Is this change non-trivial? (see decision rule below)    │
            └───────────────┬───────────────────────────┬─────────────┘
                       yes  │                       no   │
                            ▼                            ▼
                   ┌─────────────────┐          ┌──────────────────┐
                   │  OpenSpec lane  │          │  Fast-path lane  │
                   └────────┬────────┘          └────────┬─────────┘
   /opsx:propose "<idea>"   │             /plan (optional, light) or
   → proposal.md            │             straight to TDD          │
   → design.md              │                            │
   → tasks.md  (THIS is the │                            │
   review with human  ◀──── plan — don't also /plan)     │
                            │                            │
                            ▼                            ▼
                   ════════════ ECC execution loop (per task) ════════════
                   1. search-first   (research before code)
                   2. tdd-workflow   (RED = a spec scenario as a failing test
                                      → GREEN → REFACTOR, ≥80% changed-line cov)
                   3. reviewer agents (code / security / python / fastapi / mle / db)
                   4. verification-loop / eval-harness (loop until criteria met)
                   ══════════════════════════════════════════════════════
                            │
                            ▼
                   update sysdoc/  (if system shape changed — see CLAUDE.md §3.5)
                            │
                            ▼
                   /opsx:archive   (spec-first lane only — fold specs back)
                            │
                            ▼
                   quiz-me   (lock in understanding of what was built)  [opt]
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

## Three tools live "before code" — which one?

`grill-me`, `/plan`, and `/opsx:propose` all happen before you write code, so they look
redundant. They are not — they produce different things:

| Tool | Produces | Persisted? | Use when |
|------|----------|------------|----------|
| `grill-me` | clarity (a summary) | no | the idea is still fuzzy *in your own head* |
| `/opsx:propose` | `proposal/design/tasks.md` | yes (archived) | non-trivial change (spec-first lane) |
| `/plan` | an in-conversation checklist | no | small/medium change, want steps without the ceremony |

**The rule that removes the confusion:**

- `/plan` and `/opsx:propose` are the **same activity at two weights — pick ONE, never both.**
  In the spec-first lane, `tasks.md` *is* your plan; running `/plan` on top of it is planning
  twice. In the fast-path lane, `/plan` is the lightweight option (or skip straight to TDD).
- `grill-me` sits **before** either. It's a pre-step, not a substitute: it turns "I sort of
  know what I want" into something concrete enough to write down. Clear head? Skip it.

## "Will opsx:propose → tdd-workflow let the spec drift?"

No — *if* you respect the causal chain that ties them together:

```
spec scenarios  →  become your RED tests  →  tests drive the code
```

The `specs/` directory in an OpenSpec change holds requirements **and scenarios**. Your
first TDD step (RED) is to encode one of those scenarios as a failing test. So the code
isn't running *parallel* to the spec (free to diverge) — it's pulled along *by* the spec,
through the tests. One chain, not two parallel tracks.

The only thing that actually causes drift: discovering mid-implementation that the spec was
wrong or incomplete, and then **silently coding around it.** Don't. The correct move is to
go back and amend the proposal, then let `/opsx:archive` reconcile the final spec with what
was actually built. Spec doesn't drift on its own — *you* drift it by bypassing it.

## Worked example (spec-first)

```
grill-me                  → (idea was fuzzy) one-at-a-time questions surface the
                            double-charge race, the retry semantics, the key TTL
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

/opsx:archive           → specs folded back
sysdoc/ARCHITECTURE.md  → record the idempotency-key decision + tradeoffs
sysdoc/RUNBOOK.md       → add the new env vars (REDIS_URL, IDEMPOTENCY_TTL)
sysdoc/OVERVIEW.md      → note the new "Payments" component in the component table
quiz-me                 → (optional) test your grasp: "why does the key need a TTL?"
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
