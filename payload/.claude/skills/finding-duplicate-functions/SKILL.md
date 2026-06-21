---
name: finding-duplicate-functions
description: Use when auditing a codebase for semantic duplication — functions that do the same thing but have different names or implementations. Especially useful for LLM-generated Python code, where new functions get created instead of reusing existing ones.
origin: obra/superpowers-lab (MIT), ported to Python for agentkit
---

# Finding Duplicate-Intent Functions

## Overview

LLM-generated codebases accumulate semantic duplicates: functions that serve the same
purpose but were implemented independently. Classical copy-paste detectors find *syntactic*
duplicates but miss "same intent, different implementation."

This skill uses a two-phase approach: classical extraction (cheap, deterministic) followed
by LLM-powered intent clustering (only where it adds value). It complements the
`refactor-cleaner` agent, which removes *dead* code — this finds *live but redundant* code.

> The haiku-for-categorize / opus-for-detect split is a cost-tiering decision — see
> `cost-aware-llm-pipeline`. Categorization is cheap classification; duplicate detection
> needs reasoning, so it gets the stronger model.

## When to Use

- The codebase grew organically with multiple contributors (human or LLM).
- You suspect utility functions have been reimplemented multiple times.
- Before a major refactor, to identify consolidation opportunities.
- After syntactic duplicate detection — this catches what that misses.

## Process

```
1. Extract function catalog   scripts/extract_functions.py   → catalog.json
2. Categorize by domain        haiku + scripts/categorize-prompt.md      → categorized.json
3. Keep categories with 3+ functions                                     → per-category lists
4. Find duplicates per category opus + scripts/find-duplicates-prompt.md → duplicates.json
5. Generate prioritized report                                           → report.md
6. Human review & consolidate
```

### Phase 1: Extract the Function Catalog

Run the extractor (uses Python's `ast` — robust, no regex guessing). It captures public
functions and excludes tests:

```bash
python scripts/extract_functions.py src/ -o catalog.json
```
Options: `-o FILE` output (default stdout), `--include-private` keep `_`-prefixed,
`--include-tests` keep `test_*`/`*_test.py`.

### Phase 2: Categorize by Domain (haiku)

Dispatch a **haiku** subagent with `scripts/categorize-prompt.md`, inserting `catalog.json`
where indicated. Save as `categorized.json`. Haiku is cost-effective here and exact accuracy
matters less than for Phase 4.

### Phase 3: Split into Categories

Keep only categories with **3+ functions** — fewer isn't worth an LLM pass. One group per
category focuses the comparison and cuts noise.

### Phase 4: Find Duplicates Per Category (opus)

For each category, dispatch an **opus** subagent with `scripts/find-duplicates-prompt.md`.
Per-category scope keeps the comparison tractable and the output precise.

### Phase 5: Generate Report

Group findings by confidence (HIGH/MEDIUM/LOW). For each duplicate group: the survivor, the
duplicates to remove, and the call sites to update.

### Phase 6: Human Review

For HIGH-confidence groups: verify the survivor has tests, update callers to use it, delete
the duplicates, run the suite (`verification-loop`).

## High-Risk Duplicate Zones

Focus extraction here first — they accumulate duplicates fastest:

| Zone | Common Duplicates |
|------|-------------------|
| `utils/`, `helpers/`, `lib/` | General utilities reimplemented |
| Validation code | Same checks written multiple ways |
| Error formatting | Exception-to-string conversions |
| Path manipulation | Joining, resolving, normalizing paths |
| String formatting | Case conversion, truncation, escaping |
| Date/time formatting | Same formats implemented repeatedly |
| API response shaping | Similar transforms for different endpoints |

## Common Mistakes

- **Extracting too much.** Focus on public/exported functions (the default). Private helpers
  are less likely to be duplicated across files.
- **Skipping categorization.** Running detection on the full catalog produces noise.
- **Using haiku for detection.** Fine for categorizing, but it misses subtle semantic
  duplicates. Use opus for the actual analysis.
- **Consolidating without tests.** Before deleting, ensure the survivor has tests covering
  every use case of the deleted functions — otherwise you trade duplication for regressions.

## Files (in this directory)

- `scripts/extract_functions.py` — `ast`-based catalog extractor (runnable).
- `scripts/categorize-prompt.md` — haiku prompt template for Phase 2.
- `scripts/find-duplicates-prompt.md` — opus prompt template for Phase 4.
