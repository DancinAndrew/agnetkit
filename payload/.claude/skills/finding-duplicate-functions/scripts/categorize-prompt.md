# Categorize Prompt (Phase 2 — haiku)

Dispatch a **haiku** subagent with this prompt. Replace `{{CATALOG_JSON}}` with the contents
of `catalog.json` from Phase 1. Save the result as `categorized.json`.

---

You are grouping Python functions by their **domain of responsibility** so a later pass can
look for duplicates within each group.

Here is a catalog of functions (name, file, signature, docstring):

```json
{{CATALOG_JSON}}
```

Assign each function to exactly ONE domain category. Use concise, reusable category names so
functions that do similar work land in the same bucket. Prefer these where they fit, and add
others as needed:

- `validation` — input checks, guards, assertions
- `path-handling` — joining/resolving/normalizing filesystem paths
- `string-formatting` — case conversion, truncation, escaping, templating
- `datetime` — parsing/formatting/arithmetic on dates and times
- `serialization` — to/from JSON, dict, bytes; (de)serialization
- `db-access` — queries, connections, ORM helpers
- `http` — request/response shaping, client calls
- `error-formatting` — exception-to-string, error envelopes
- `config` — settings/env loading
- `misc` — anything that doesn't fit

Output ONLY valid JSON, an array of objects, each:

```json
{ "name": "...", "file": "...", "line": 0, "category": "..." }
```

Do not include commentary outside the JSON.
