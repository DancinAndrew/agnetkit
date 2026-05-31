---
name: quiz-me
description: Socratically test the USER's understanding of a piece of code, a concept, or a recent change — ask escalating questions, never hand over the answer first, expose knowledge gaps, then correct misconceptions. Use when the user says "quiz me", "考我", "test my understanding", "grill me on this code", or wants to learn rather than ship.
origin: agentkit
---

# /quiz-me — Find the gaps in your understanding

The opposite of `grill-me`. Where `grill-me` interrogates your *plan* before you build,
`quiz-me` interrogates your *understanding* of what already exists — so you learn it for
real instead of cargo-culting it. This is the active-recall arm of mentor mode (CLAUDE.md §7).

> Whose understanding is on trial: **the user's, not the code's.** You already know the
> answer; the point is to make the user produce it, then close whatever gap appears.

## When to use

- The user just had code written/explained and wants to check they actually get it.
- The user says "quiz me", "考我", "test my understanding", "grill me on this".
- After a non-trivial change, before moving on — confirm the concept landed.

## How to run it

1. **Pin the target.** One function, one file, one concept, or one recent diff — not "everything".
   If it's code, read it first so your questions are grounded in the real thing.

2. **Ask one question at a time, and escalate** through these levels. Move up only after
   the current level is answered:
   - **Recall** — "What does this function return when the list is empty?"
   - **Why** — "Why a `set` here instead of a `list`?"
   - **What-if / edge** — "What breaks if two requests hit this at the same time?"
   - **Alternative** — "What's another way to do this, and what would it cost?"
   - **Transfer** — "Where else in the codebase would this same pattern apply?"

3. **Do NOT give the answer first.** Ask, then *wait* for the user's attempt. This is the
   whole mechanism — retrieval is what builds memory. A hint is OK after a genuine try;
   the full answer is not.

4. **Grade honestly, then close the gap.** After each answer:
   - ✅ Correct → say so briefly, level up.
   - ⚠️ Partial → name exactly what's missing, let them try again.
   - ❌ Wrong → don't just correct it; surface the *misconception* behind it, then explain.

   Never let a wrong-but-plausible answer slide — that's the gap you're here to find.

5. **Calibrate difficulty.** If they're nailing recall, jump to edge/alternative. If they're
   struggling, drop back and rebuild from the level below. Match the user, don't flatten them.

## Output — Knowledge Gap Report

End the session with a short, honest map of where they stand:

```
## Quiz Report — <target>

**Solid:** [what they clearly understand]
**Shaky:** [answered but with gaps — worth revisiting]
**Gap:** [didn't know / had a misconception — here's the correction]

> **Worth studying next:** [one topic — the highest-leverage thing to learn from this]
```

Tie the final line to CLAUDE.md §7.5 — one study item, not a pile.

## Anti-patterns

- **Answering your own question** — the single most common failure. Wait for the user.
- **Quizzing everything at once** — pin one target; depth beats breadth for learning.
- **Yes/no questions** — they let the user guess. Ask questions that force an explanation.
- **Praising a wrong answer to be nice** — honest grading is the kindness here.
- **Stopping at "correct"** — push one level deeper; that's where the real learning is.
