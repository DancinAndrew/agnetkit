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
1. Extract function catalog   (ast — deterministic)        → catalog.json
2. Categorize by domain       (haiku subagent)             → categorized.json
3. Keep categories with 3+ functions                       → categories/*.json
4. Find duplicates per category (opus subagent per group)  → duplicates/*.json
5. Generate prioritized report                             → report.md
6. Human review & consolidate
```

### Phase 1: Extract the Function Catalog

Use Python's `ast` module (robust — no regex guessing). Capture exported/public functions
and their signatures; exclude tests (`test_*`, `*_test.py`, `conftest.py`) — test helpers are
rarely consolidation targets.

```python
import ast, json, sys
from pathlib import Path

def extract(root: str) -> list[dict]:
    out = []
    for path in Path(root).rglob("*.py"):
        if path.name.startswith("test_") or path.name.endswith("_test.py"):
            continue
        tree = ast.parse(path.read_text(), filename=str(path))
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                if node.name.startswith("_"):       # skip private helpers
                    continue
                out.append({
                    "name": node.name,
                    "file": str(path),
                    "line": node.lineno,
                    "args": [a.arg for a in node.args.args],
                    "doc": ast.get_docstring(node) or "",
                })
    return out

if __name__ == "__main__":
    json.dump(extract(sys.argv[1]), sys.stdout, indent=2)
```

### Phase 2: Categorize by Domain (haiku)

Dispatch a **haiku** subagent: given the catalog, bucket each function into a domain
(validation, path-handling, formatting, serialization, db-access, …). Output
`categorized.json`. Haiku is cost-effective here and accuracy matters less than for Phase 4.

### Phase 3: Split into Categories

Keep only categories with **3+ functions** — fewer than that isn't worth an LLM pass. One
JSON file per category focuses the comparison and cuts noise.

### Phase 4: Find Duplicates Per Category (opus)

For each category, dispatch an **opus** subagent: "Which of these functions do the same
thing? Group them, pick the best survivor (the one with tests + clearest implementation),
rate confidence HIGH/MEDIUM/LOW." Per-category scope keeps the comparison tractable.

### Phase 5: Generate Report

Group findings by confidence. For each duplicate group: the survivor, the duplicates to
remove, and the call sites to update.

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

- **Extracting too much.** Focus on public/exported functions. Private helpers are less
  likely to be duplicated across files.
- **Skipping categorization.** Running duplicate detection on the full catalog produces
  noise. Categories focus the comparison.
- **Using haiku for detection.** Haiku is fine for categorizing but misses subtle semantic
  duplicates. Use opus for the actual analysis.
- **Consolidating without tests.** Before deleting, ensure the survivor has tests covering
  every use case of the deleted functions — otherwise you trade duplication for regressions.
