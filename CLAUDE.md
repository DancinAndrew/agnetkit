# CLAUDE.md — operating contract

This project is wired with **agentkit**: a layered AI software-development workflow.
Three layers, top governs the ones below:

1. **Principles** (this file) — how you think and how you change code.
2. **Spec layer** — OpenSpec in `openspec/` — agree on *what* and *why* before code.
3. **Execution layer** — ECC agents, skills, and rules in `.claude/` — *do* and *verify* the work.

> If guidance ever conflicts: **Principles > Spec layer > Execution rules**. The rules
> elaborate the principles; they never override them.

---

## 1. Principles (always apply)

These four principles are the contract. They bias toward **caution over speed**; for
trivial tasks (typo, obvious one-liner) use judgment — not every change needs full rigor.

### 1.1 Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 1.2 Simplicity First
**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Test: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 1.3 Surgical Changes
**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that *your* changes made unused; leave pre-existing
  dead code unless asked.

Test: every changed line traces directly to the request.

### 1.4 Goal-Driven Execution
**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

Strong success criteria let you loop independently. Weak criteria ("make it work")
require constant clarification.

---

## 2. Routing: when to spec, when to fast-path

Decide the lane **before** writing code.

**Spec-first (use OpenSpec)** if *any* of these hold:
- new feature or module;
- requirements are ambiguous or admit multiple interpretations;
- it touches **auth, payments, money, or the data model / migrations**;
- it spans multiple files or services;
- it changes externally observable behavior.

→ `/opsx:propose "<change>"` → review `proposal.md` + `design.md` + `tasks.md` with the
human → implement each task through the execution loop below → `/opsx:archive`.

**Fast-path (skip OpenSpec)** for: typos, comments, formatting, one-line fixes, and
obviously-scoped local changes. Still write a failing test first if behavior changes.

> Unsure which lane? It's spec-first. (Principle 1.1.)

---

## 3. Execution loop (per task / per fix)

1. **Research first** — use the `search-first` skill and `docs-lookup` agent to read the
   codebase and real docs before writing. No assumptions about APIs you haven't checked.
2. **TDD** — `tdd-workflow` skill: RED (failing test) → GREEN (minimal code) → REFACTOR.
   Aim for ≥80% coverage on changed code.
3. **Review** — delegate, don't eyeball:
   - `code-reviewer` — always.
   - `security-reviewer` — anything touching auth, payments, PII, or external input.
   - `python-reviewer` / `fastapi-reviewer` — Python and API code.
   - `mle-reviewer` — RAG / ML pipeline, eval, serving, or monitoring changes.
   - `database-reviewer` — schema, migrations, or non-trivial queries.
   - `silent-failure-hunter` — when adding error handling or touching async/IO paths.
4. **Verify** — `verification-loop` / `eval-harness` skills: check against the task's
   success criteria. Loop until green. Don't declare done on a partial pass.
5. **Archive** (spec-first only) — `/opsx:archive` to fold the change's specs back.

---

## 4. Subagents available

`planner` · `architect` · `tdd-guide` · `code-reviewer` · `security-reviewer` ·
`python-reviewer` · `fastapi-reviewer` · `database-reviewer` · `mle-reviewer` ·
`build-error-resolver` · `refactor-cleaner` · `doc-updater` · `docs-lookup` ·
`silent-failure-hunter`

Delegation triggers: see `.claude/rules/common/agents.md`. Prefer delegating a bounded
task to a subagent over inlining everything in the main context.

---

## 5. Rules (authoritative operational detail)

The principles above are the contract; the rules below are the detailed elaboration.
Where they overlap, rules win on *specifics* (style, thresholds, commands).

Always-on (imported):
@.claude/rules/common/development-workflow.md
@.claude/rules/common/coding-style.md
@.claude/rules/common/testing.md
@.claude/rules/common/security.md
@.claude/rules/common/git-workflow.md
@.claude/rules/python/coding-style.md
@.claude/rules/python/fastapi.md
@.claude/rules/python/testing.md

Load on demand (present in `.claude/rules/`, not auto-imported to keep context lean):
`common/patterns.md`, `common/code-review.md`, `common/performance.md`,
`common/agents.md`, `common/hooks.md`, `python/patterns.md`, `python/security.md`,
`python/hooks.md`.

> Trim or extend the import list above to taste — it is the always-on context budget.

---

## 6. Project-specific

<!-- Add your stack/domain rules here. A FastAPI + RAG starter lives in
     templates/CLAUDE.project.md (in the agentkit repo). Keep this section short and
     concrete: stack versions, conventions Claude must follow, paths it must respect. -->
