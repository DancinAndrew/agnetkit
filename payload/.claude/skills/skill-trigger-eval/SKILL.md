---
name: skill-trigger-eval
description: Use when you have written or edited a skill and want to verify its description triggers at the right times and not the wrong ones. Measures trigger precision/recall for a skill's description field.
origin: agentkit-original, inspired by VectifyAI/OpenKB skill-eval
---

# Skill Trigger Evaluation

## Overview

A skill is only useful if it fires when it should and stays quiet when it shouldn't. The
entire trigger decision rides on one line: the `description` frontmatter. As a skill library
grows (agentkit ships 30+), two failure modes appear:

- **Under-triggering** — the description is too narrow/vague, so the skill never gets picked
  even when relevant.
- **Over-triggering** — the description is too broad, so it fires on unrelated tasks and
  crowds out the right skill.

This skill turns "is the description good?" from a guess into a measurable number. It is the
trigger-routing counterpart to `eval-harness` (which evaluates whether *code* is correct);
here we evaluate whether *skill selection* is correct.

## When to Use

- Right after writing a new skill (e.g. via `learn` / `continuous-learning-v2`).
- After editing an existing skill's `description`.
- When you notice a skill firing on the wrong tasks, or never firing when expected.

## The Loop

```
1. GENERATE  positive + negative prompts for the target skill
2. JUDGE     for each prompt, would this description cause the skill to trigger?
3. SCORE     compute precision / recall against the labels
4. FIX       rewrite the description; re-run until clean
```

### Phase 1: Generate Prompts

For the target skill, generate two labelled sets (an LLM does this well):

- **Positives (should trigger)** — 8–12 user requests that genuinely call for this skill,
  phrased diversely (synonyms, indirect asks, different domains).
- **Negatives (should NOT trigger)** — 8–12 requests that are *near misses*: adjacent topics,
  overlapping vocabulary, or tasks a sibling skill should own.

> Near-miss negatives are the whole point. "Write me a poem" is a useless negative for a
> debugging skill; "the linter is complaining about my types" is a useful one — it shares
> vocabulary with debugging but belongs to a different skill.

```json
{
  "skill": "systematic-debugging",
  "positives": [
    "this test passes locally but fails in CI, no idea why",
    "the endpoint returns 500 intermittently and I can't reproduce it"
  ],
  "negatives": [
    "add a try/except around this DB call",        // -> error-handling
    "review my PR for security issues"             // -> security-review
  ]
}
```

### Phase 2: Judge (grader)

For each prompt, give a **grader** subagent *only the candidate skill's `description`* (not
its body) plus the prompt, and ask: "Based solely on this description, should this skill
trigger for this request? yes/no." This isolates the description — the only thing the harness
actually routes on.

For a sharper test, include the descriptions of 2–3 sibling skills and ask the grader to pick
*which* skill fires — this catches over-triggering that a yes/no test misses.

### Phase 3: Score

```
precision = correct triggers / all triggers       (high = few false fires)
recall    = correct triggers / all positives       (high = rarely missed)
```

- Low **recall** → description too narrow or jargon-heavy → broaden it, add the phrasings
  from the missed positives.
- Low **precision** → description too broad → tighten the scope, name what it is NOT for,
  or hand the boundary case to the sibling skill that should own it.

Target: recall ≥ 0.9 on positives, precision ≥ 0.9 on the near-miss negatives.

### Phase 4: Fix and Re-run

Edit only the `description`. Re-run the loop. The failing prompts ARE your regression set —
keep them so the next description edit can't silently reintroduce the bug.

## Anti-Patterns

- **Easy negatives.** Unrelated prompts always pass; they prove nothing. Use near misses.
- **Judging the body, not the description.** The harness routes on the description — eval the
  description in isolation, or you're testing the wrong thing.
- **Overfitting the description to the eval prompts.** Keep the prompt set diverse and
  refresh it; a description tuned to 10 exact phrasings won't generalize.
- **Skipping the sibling-skills test.** Yes/no in isolation hides over-triggering. The "which
  skill fires?" framing is what surfaces routing collisions.
