---
name: grill-me
description: Interrogate the user about a plan or design BEFORE any code is written — one question at a time, each with a recommended answer — until every branch of the decision tree is resolved and ambiguity hits zero. Use when the user wants to stress-test a plan, says "grill me", "拷問我的設計", or is about to build something non-trivial.
origin: agentkit (adapted from Matt Pocock's grill-me)
---

# /grill-me — Stress-test the plan before you build it

The cheapest bug to fix is the one you catch before writing the code. This skill
forces the design into the open by interviewing the user relentlessly until there
is nothing left to assume.

> Sits in the same slot as `/plan` and the OpenSpec proposal — run it **first**, then
> feed its summary into them. It does not write code; it removes ambiguity.

## When to use

- New feature or module, especially if requirements feel fuzzy.
- Before `/plan` or `/opsx:propose` on anything spec-first (auth, payments, data model,
  multi-file, externally observable behavior).
- Whenever the user says "grill me", "拷問我", "stress-test this", or hands over a vague idea.

## The rules of the grilling

1. **One question at a time.** Never dump a list. Ask, wait, then ask the next — each
   question informed by the previous answer. Walk *down* the decision tree, resolving
   dependencies before the things that depend on them.

2. **Every question carries a recommended answer.** End each question with
   `→ Recommended: <X>, because <Y>`. If the answer is obvious, say so — the user can
   just reply "yes" and you move on. This keeps a 40-question grilling fast, not exhausting.

3. **Answer from the codebase whenever you can.** If a question is answerable by reading
   the repo (what does the current schema look like? is Redis already a dependency?),
   *go read it* instead of asking. Only ask the human what the code can't tell you.

4. **Chase the branches, not just the happy path.** Cover, in dependency order:
   - **Goal & scope** — what done looks like; what's explicitly out of scope.
   - **Data model** — entities, ownership, lifecycle, migrations.
   - **Contracts** — API shape, inputs, outputs, status codes, error shape.
   - **Edge cases & failure** — empty/null, concurrency, partial failure, retries, idempotency.
   - **Security & trust** — authz, untrusted input, secrets, blast radius.
   - **Trade-offs** — what we're choosing NOT to do, and the cost if requirements grow.

5. **Stop when ambiguity hits zero.** When you can't find a question whose answer would
   change the implementation, you're done — don't pad it.

## Output

Close with a **Shared Understanding** summary the user (or future-you) can act on:

```
## Shared Understanding — <feature>

**Goal:** ...
**In scope / Out of scope:** ...
**Data model:** ...
**Contract:** ...
**Edge cases resolved:** ...
**Security:** ...
**Decisions & trade-offs:** ...   (each: chose X over Y because Z)
**Open questions left:** ...       (ideally none)

→ Next: feed this into /plan or /opsx:propose.
```

## Anti-patterns

- **Question dumping** — 40 questions in one message. The whole point is one-at-a-time.
- **Asking what the code already answers** — read first, ask second.
- **Interrogating a typo** — this is for non-trivial design, not one-line fixes (fast-path those).
- **No recommendation** — a bare question makes the user do all the work; always propose an answer.
- **Grilling forever** — if the next question wouldn't change the code, stop.
