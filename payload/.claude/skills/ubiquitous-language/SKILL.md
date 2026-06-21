---
name: ubiquitous-language
description: Build and maintain a project glossary so the human and the AI use the same words for the same things. Use when starting work on an unfamiliar codebase, when the AI keeps misnaming domain concepts, before grill-me / planning on a domain-heavy feature, or when the user says "build a glossary" / "建立術語表". Keep the glossary loaded in context during design and implementation.
origin: agentkit-original, inspired by Eric Evans' Domain-Driven Design (Ubiquitous Language) and obra's "Software Fundamentals" talk
---

# Ubiquitous Language — one vocabulary for human and AI

Most human↔AI misfires are not coding failures, they are **vocabulary failures**: the
human says "order", the model hears "purchase", and writes code against the wrong concept.
Domain-Driven Design's fix is a **Ubiquitous Language** — one agreed set of terms that shows
up identically in conversation, in the glossary, and in the code (class names, functions,
variables). This skill builds that glossary from the real codebase and keeps it in context.

> **Why a glossary and not just "be careful":** a term map written into the context window
> acts as a semantic anchor. It measurably shortens the model's reasoning and stops it from
> drifting to a synonym mid-session. The cost is one Markdown file; the payoff is every
> later prompt landing on the right concept.

## When to use

- **Onboarding a codebase** — before the first real change, so names mean the same thing.
- **Domain-heavy work** — finance, medical, logistics, anything with insider vocabulary.
- **Before `grill-me` / `/plan` / `/opsx:propose`** — load the glossary so the design
  conversation uses settled terms instead of inventing new ones.
- **When you catch drift** — the AI calls the same entity three different names across a
  session, or a domain expert's word got silently translated into the wrong code concept.

## The loop

```
1. EXTRACT   scan the codebase for recurring domain nouns (entities, states, roles, events)
2. DEFINE    one row per term: Term | Definition | Code symbol | NOT to be confused with
3. RECONCILE surface conflicts & synonyms to the human; pick ONE canonical term each
4. LOAD      keep GLOSSARY.md open in context during design and implementation
5. ENFORCE   new code uses canonical terms; new domain words get added back to the glossary
```

### Phase 1: Extract

Pull candidate terms from where the domain actually lives — not every identifier, just the
ones that carry business meaning:

- model / entity / table names, enum values and status strings (`pending`, `settled`),
- recurring function and route nouns (`reconcile`, `dispatch`, `void`),
- words that appear in docstrings, PRDs, and commit messages but aren't generic programming
  terms.

Skip framework noise (`Controller`, `Service`, `utils`) unless the project gives them a
special domain meaning.

### Phase 2: Define — the glossary table

Write `GLOSSARY.md` (project root or `sysdoc/`). One row per term:

| Term | Definition (1 sentence, domain language) | Code symbol | Not to be confused with |
|------|------------------------------------------|-------------|-------------------------|
| Settlement | Money actually moved between two accounts and recorded | `Settlement`, `settle()` | Authorization (only reserves funds) |
| Void | Cancel an authorization *before* settlement | `void_authorization()` | Refund (reverses *after* settlement) |

The fourth column is the highest-value one: it encodes the **near-miss** distinctions that
cause the worst bugs (void vs refund, authorization vs settlement).

### Phase 3: Reconcile

This is the human-in-the-loop step. Where extraction found two words for one concept, or one
word for two concepts, **ask the user to pick the canonical term** — don't choose silently.
Record the decision (and the rejected synonym) so it doesn't get re-litigated.

### Phase 4 & 5: Load and enforce

- During `grill-me`, planning, and implementation, keep `GLOSSARY.md` in context.
- Code that introduces a domain concept must use its canonical term — in the class name, the
  function name, the variable. The glossary is the source of truth for naming.
- When a genuinely new domain word appears, add a row **before** writing the code that uses
  it — the glossary leads the code, not the other way around.

## Pairing

- **Before `grill-me`** — settled vocabulary makes the grilling sharper; the questions can
  use real domain terms instead of negotiating them on the fly.
- **Feeds `architecture-decision-records`** — ADRs should reference glossary terms so a
  decision and the code it shapes speak the same language.
- **Complements `finding-duplicate-functions`** — duplicates often hide behind synonym names
  (`getUser` vs `fetchAccount`); a canonical vocabulary makes the duplication visible.

## Anti-patterns

- **Dumping every identifier into the glossary.** It's a *domain* vocabulary, not a symbol
  index. Generic plumbing doesn't belong.
- **Writing it once and letting it rot.** A stale glossary is worse than none — it asserts
  names the code no longer uses. Update it when the domain changes.
- **Choosing the canonical term yourself on a real ambiguity.** Reconciliation is the human's
  call; that's where the domain knowledge lives.
- **Building it for a throwaway script.** This is for codebases that live long enough for
  vocabulary drift to cost something.
