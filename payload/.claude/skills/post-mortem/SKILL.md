---
name: post-mortem
description: Run a blameless incident retrospective after something breaks — a production bug, a failed deploy, data corruption, or an AI change that went wrong. Asks not just "what broke" but "why did our process let it through", then turns the answer into concrete updates to specs, tests, CLAUDE.md, and review checklists. Use when the user says "post-mortem", "復盤", "事後檢討", or after resolving any non-trivial incident.
origin: agentkit-original, from the AI-Assisted Loop Engineering SOP
---

# Post-mortem — fix the process, not just the bug

A bug fixed is a symptom treated. A post-mortem asks the harder question:

> **Why did this error pass through every layer of our process and reach production?**

The output is not "we fixed it" — it's a set of changes to the *process* (spec template,
test checklist, CLAUDE.md, review steps, monitoring) so this *class* of error can't pass
through again. This is the feedback loop that makes the workflow itself improve over time.

> **Blameless by design:** the subject is the process, never the person (or the AI). "The
> review didn't catch it" is a finding; "you should have caught it" is not. Blame kills the
> honesty the retrospective depends on.

## When to use

- After resolving a production bug, failed deploy, data error, or outage.
- After an AI-made change broke something — scope creep, a silent regression, a wrong assumption.
- When the user says "post-mortem", "復盤", "事後檢討", "why did this happen".
- **Not** during the incident — stabilize first (see Order of operations), retrospect after.

## Order of operations

```
Production is broken → STOP. Stabilize first:
  1. Assess severity & blast radius
  2. Hotfix or rollback to stop the bleeding
  3. Confirm the system is stable
  4. Add a test that reproduces the failure
THEN, once stable → run this post-mortem.
```

Never delay a rollback to "do it properly". Stop the bleeding, then write the retrospective.

## The template

Write `docs/postmortems/YYYY-MM-DD-<slug>.md`:

```markdown
# Post-mortem: <incident>

## 1. Summary
What broke, who/what was affected, for how long.

## 2. Timeline
- Introduced:  <when the cause landed>
- Triggered:   <when it started failing>
- Detected:    <when we noticed — and how>
- Resolved:    <when it was stable again>
  (The gap between Triggered and Detected is itself a finding.)

## 3. Impact
Features, users, data integrity, security/financial exposure.

## 4. Root cause
Direct cause (the line/change) AND the deeper process cause.
Use "5 Whys" — keep asking why until you reach a process gap, not a person.

## 5. Resolution
Hotfix? Rollback? The permanent fix and the test that now guards it.

## 6. Why didn't our process catch it?   ← the core of the retrospective
- [ ] Spec — was the case missing or ambiguous?
- [ ] Tests — was there a coverage gap? (you should have just added the reproducing test)
- [ ] Review — what would a reviewer have needed to see to catch it?
- [ ] Monitoring/alerting — why the silent gap between Triggered and Detected?
- [ ] PR size — was the change too big to review meaningfully?
- [ ] AI scope — did the AI exceed the spec, or fill an ambiguity with a wrong guess?

## 7. Action items
Concrete, owned, checkable. Each maps to a process artifact in §8.

## 8. Process changes  ← what makes this worth doing
- [ ] Spec template     — add the missing question/section
- [ ] Test checklist    — add the class of case that was missed
- [ ] CLAUDE.md / rules — encode the lesson so future sessions inherit it
- [ ] Review checklist  — add the check a reviewer needed
- [ ] Monitoring        — add the alert that would have shrunk Detected
```

## The point is §6 and §8

§1–§5 are normal incident notes. The value is §6 (*why the process missed it*) feeding §8
(*the process change*). A post-mortem that ends at "we fixed the bug" wasted the incident.

> **Feeds the rest of agentkit:** §8 action items land as edits to `CLAUDE.md`, the rules in
> `.claude/rules/`, the `grill-me` / spec templates, or a new `continuous-learning-v2`
> instinct. The retrospective is where an incident becomes a permanent guardrail.

## Anti-patterns

- **Blame.** The moment it's about who erred, people stop being honest. It's about the process.
- **Stopping at the symptom fix.** No §8 change → the same class of bug returns.
- **Retrospecting before stabilizing.** Rollback first; the write-up can wait an hour.
- **Action items with no owner or no checkable done-state.** Those never happen.
- **A post-mortem for a trivial typo.** Reserve it for incidents with real blast radius.
