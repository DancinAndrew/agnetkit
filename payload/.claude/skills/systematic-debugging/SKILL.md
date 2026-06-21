---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes. Find root cause first — symptom patches are failure.
origin: obra/superpowers (MIT), ported to Python/pytest for agentkit
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

This is the missing counterpart to `error-handling` (how to *write* error handling) — this
skill is how to *find* the bug. For confirming a fix actually worked, pair with
`verification-loop`; for the failing test in Phase 4, pair with `tdd-workflow`.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

Use for ANY technical issue: test failures, production bugs, unexpected behavior,
performance problems, build failures, integration issues.

**ESPECIALLY when:** under time pressure (emergencies make guessing tempting), "just one
quick fix" seems obvious, you've already tried multiple fixes, the previous fix didn't work,
or you don't fully understand the issue.

**Don't skip when:** the issue seems simple (simple bugs have root causes too), you're in a
hurry (rushing guarantees rework), or someone wants it fixed NOW (systematic is faster than
thrashing).

## The Four Phases

Complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read error messages carefully.** Don't skip past errors or warnings — they often
   contain the exact solution. Read tracebacks completely; note line numbers, file paths,
   exception types.
2. **Reproduce consistently.** Can you trigger it reliably? Exact steps? Every time? If not
   reproducible → gather more data, don't guess.
3. **Check recent changes.** `git diff`, recent commits, new dependencies, config or
   environment differences.
4. **Gather evidence in multi-component systems.** When the system has multiple boundaries
   (FastAPI route → service → repository → DB), add diagnostic instrumentation at each
   boundary BEFORE proposing fixes — log what enters and exits each component, then run once
   to see WHERE it breaks.

   ```python
   import logging, os
   log = logging.getLogger("debug")

   # Boundary 1: request layer
   log.error("ROUTE in: user_id=%r filters=%r", user_id, filters)
   # Boundary 2: service layer
   log.error("SERVICE: db_url=%s pool=%s", os.environ.get("DATABASE_URL", "UNSET"), pool.status)
   # Boundary 3: repository layer
   log.error("REPO query: %s params=%r", query, params)
   # Boundary 4: actual call
   rows = await conn.fetch(query, *params)
   log.error("REPO out: rows=%d", len(rows))
   ```

   This reveals which layer fails (request ✓ → service ✓ → repo ✗), so you investigate the
   *right* component instead of guessing.
5. **Trace data flow backward.** When the error is deep in the call stack, the instinct is
   to fix where it appears — that's a symptom. Trace backward until you find the original
   trigger, then fix at the source.

   ```
   Symptom:  asyncpg raises "relation does not exist" inside Repo.fetch()
   ↑ What called this with a bad table name?   Service.list_items(tenant)
   ↑ What passed the bad tenant?               Route handler, tenant="" (empty!)
   ↑ Where did empty come from?                Dependency default never overridden in test
   Root cause: test fixture didn't set the tenant header → empty string flowed all the way down
   ```

   When you can't trace manually, capture a stack at the dangerous operation:
   ```python
   import traceback
   log.error("about to run git init in %r\n%s", directory, "".join(traceback.format_stack()))
   ```

### Phase 2: Pattern Analysis

1. **Find working examples** — locate similar working code in the same codebase.
2. **Compare against references** — if implementing a pattern, read the reference
   implementation COMPLETELY. Don't skim.
3. **Identify differences** — list every difference between working and broken, however
   small. Don't assume "that can't matter."
4. **Understand dependencies** — what config, env, fixtures, or assumptions does it need?

### Phase 3: Hypothesis and Testing

1. **Form a single hypothesis.** State it: "I think X is the root cause because Y." Write it
   down. Be specific.
2. **Test minimally.** Make the SMALLEST possible change to test it. One variable at a time.
3. **Verify before continuing.** Worked? → Phase 4. Didn't? → form a NEW hypothesis. Don't
   stack more fixes on top.
4. **When you don't know, say so.** "I don't understand X." Don't pretend. Research or ask.

### Phase 4: Implementation

1. **Create a failing test first.** Simplest possible reproduction (a pytest case, or a
   one-off script if no framework fits). You MUST have it before fixing. Use `tdd-workflow`.
2. **Implement a single fix** addressing the root cause. ONE change. No "while I'm here"
   refactors.
3. **Verify the fix** — test passes now, no other tests broken, issue actually resolved
   (run `verification-loop`).
4. **If the fix doesn't work: STOP and count attempts.** `< 3` → return to Phase 1 with the
   new information. **`≥ 3` → stop and question the architecture (below).**
5. **If 3+ fixes failed, question the architecture.** Pattern: each fix reveals new
   coupling/shared-state elsewhere, fixes need "massive refactoring," each fix creates new
   symptoms. That's not a failed hypothesis — it's a wrong architecture. Discuss with your
   human partner before attempting fix #4.

## Defense-in-Depth (after finding root cause)

Fixing at one place feels sufficient, but a single check is bypassed by different code paths,
refactors, or mocks. Validate at EVERY layer the bad data passes through to make the bug
*structurally impossible*:

```python
# Layer 1 — Entry validation (Pydantic / FastAPI boundary)
class CreateProject(BaseModel):
    working_dir: str
    @field_validator("working_dir")
    @classmethod
    def _must_exist(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("working_dir cannot be empty")
        if not Path(v).is_dir():
            raise ValueError(f"working_dir is not a directory: {v}")
        return v

# Layer 2 — Business logic guard
def init_workspace(project_dir: str) -> None:
    if not project_dir:
        raise ValueError("project_dir required for workspace init")

# Layer 3 — Environment guard (refuse dangerous ops in the wrong context)
def git_init(directory: str) -> None:
    if os.environ.get("ENV") == "test" and not Path(directory).resolve().is_relative_to(tempfile.gettempdir()):
        raise RuntimeError(f"refusing git init outside tmp during tests: {directory}")

# Layer 4 — Debug instrumentation (forensics when the others miss)
log.debug("about to git init", extra={"directory": directory, "cwd": os.getcwd()})
```

Each layer catches what the others miss (different paths bypass entry validation; mocks
bypass business logic; edge cases need env guards). Don't stop at one validation point.

## Condition-Based Waiting (for flaky async/IO tests)

Flaky tests guess at timing with `time.sleep()` — they pass on fast machines, fail under CI
load. Wait for the actual condition, not a guess about how long it takes.

```python
import time

def wait_for(condition, description, timeout=5.0, interval=0.01):
    """Poll until condition() is truthy, or raise after timeout."""
    start = time.monotonic()
    while True:
        result = condition()
        if result:
            return result
        if time.monotonic() - start > timeout:
            raise TimeoutError(f"waiting for {description} after {timeout}s")
        time.sleep(interval)  # poll every 10ms — not every 1ms (wastes CPU)

# ❌ BEFORE: time.sleep(0.05); assert get_result() is not None
# ✅ AFTER:  wait_for(lambda: get_result() is not None, "result ready")
```
For async code use `anyio`/`asyncio` with the same poll loop. An arbitrary sleep is only
correct when testing *timed behavior itself* (debounce/throttle) — and then it must be
documented with WHY.

## Finding Which Test Pollutes State

If a file/row/global appears during the suite but you don't know which test created it,
bisect with pytest isolation:

```bash
# Run each test file in its own process; the one that leaves the artifact is the polluter.
for f in $(find tests -name 'test_*.py' | sort); do
  rm -rf .git_artifact 2>/dev/null
  python -m pytest "$f" -q >/dev/null 2>&1 || true
  [ -e .git_artifact ] && { echo "POLLUTER: $f"; break; }
done
```
Or run the whole suite with `pytest -p no:randomly --forked` (pytest-forked) to isolate
side effects, then narrow down.

## Red Flags — STOP and Return to Phase 1

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "It's probably X, let me fix that" (before tracing data flow)
- "I don't fully understand but this might work"
- "One more fix attempt" (when you've already tried 2+)
- Each fix reveals a new problem in a different place

**All of these mean: STOP.** If 3+ fixes failed, question the architecture.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | The first fix sets the pattern. Do it right from the start. |
| "I'll write the test after confirming the fix" | Untested fixes don't stick. Test-first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked; causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question the pattern, don't fix again. |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|----------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, instrument boundaries, trace backward | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare completely | Identify every difference |
| **3. Hypothesis** | Form one theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Failing test → single fix → verify | Bug resolved, tests pass |

**95% of "there's no root cause" cases are incomplete investigation.** If investigation
genuinely shows the issue is environmental/external, document what you checked, add
appropriate handling (retry/timeout/clear error), and add monitoring for next time.
