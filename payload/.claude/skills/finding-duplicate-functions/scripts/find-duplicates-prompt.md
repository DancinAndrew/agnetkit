# Find Duplicates Prompt (Phase 4 — opus)

Dispatch one **opus** subagent per category. Replace `{{CATEGORY}}` with the category name and
`{{CATEGORY_FUNCTIONS}}` with that category's function records (include the source body of each
function, not just the signature — duplicate intent hides in the implementation). Save each
result as `duplicates/{{CATEGORY}}.json`.

---

You are auditing Python functions in the **{{CATEGORY}}** domain for *semantic duplication* —
functions that accomplish the same thing, even if named differently or implemented
differently. Syntactic copy-paste is NOT the target; same-intent-different-code IS.

Functions:

```json
{{CATEGORY_FUNCTIONS}}
```

For each set of functions that share the same intent, emit a duplicate group:

- **survivor** — the one to keep. Prefer the function that (a) has tests, (b) has the clearest
  implementation, (c) is most general. State which.
- **duplicates** — the others, with their file:line.
- **confidence** — `HIGH` (clearly the same operation), `MEDIUM` (likely, needs a human look),
  `LOW` (superficially similar, may be intentional).
- **rationale** — one sentence on why they're the same intent.
- **risk** — one sentence on what could break if consolidated (different edge-case handling,
  signatures, side effects).

Single functions with no duplicate are omitted. Output ONLY valid JSON:

```json
[
  {
    "survivor": { "name": "...", "file": "...", "line": 0, "has_tests": true },
    "duplicates": [ { "name": "...", "file": "...", "line": 0 } ],
    "confidence": "HIGH",
    "rationale": "...",
    "risk": "..."
  }
]
```

Do not include commentary outside the JSON. When unsure whether two functions truly share
intent, rate `LOW` rather than inventing a match — false positives waste the reviewer's time.
