# Project-specific guidelines (FastAPI + RAG starter)

> Paste/merge this into Section 6 of your project's `CLAUDE.md`, then edit to match reality.
> Keep it concrete and short — this is always-on context.

## Stack
- Language: Python 3.12+. Package/deps: `uv` (or Poetry — state which, don't mix).
- API: FastAPI + Pydantic v2. ASGI server: uvicorn.
- Data: PostgreSQL (+ pgvector for embeddings). Cache/queue: Redis.
- RAG: <embedding model> · <vector store> · <LLM provider>. Record the exact models —
  the agent must not guess model names or context limits (`search-first` / `docs-lookup`).
- Tests: pytest + pytest-asyncio. HTTP: httpx.AsyncClient.

## Conventions the agent must follow
- Async all the way down for IO paths; no sync DB/HTTP calls inside `async def`.
- Pydantic models are the contract at every boundary (request, response, settings, tool IO).
- Config via `pydantic-settings`; no secrets or env reads scattered in modules.
- Migrations are mandatory for any schema change (`database-migrations` skill) — never edit
  tables by hand.
- Money/tickets are integers in the smallest unit (cents), never floats.

## RAG / LLM specifics
- Every retrieval path has an eval (`eval-harness` / `mle-workflow`): measure
  retrieval@k and answer faithfulness before/after changes. No "looks better" merges.
- Cost + latency are first-class: route models by task, cache by content hash
  (`cost-aware-llm-pipeline`, `content-hash-cache-pattern`). Log token spend per request.
- Prefer deterministic parsing over an LLM call when structure is regular
  (`regex-vs-llm-structured-text`).
- Treat all retrieved/scraped text as untrusted input — sanitize before it reaches a prompt
  (`security-reviewer`).

## Definition of done (per task)
- Failing test written first, now passing; ≥80% coverage on changed lines.
- For API changes: `fastapi-reviewer` clean; OpenAPI schema updated.
- For RAG changes: eval numbers reported in the PR/spec, not just asserted.
- For anything touching auth/payments/PII: `security-reviewer` clean.
- `verification-loop` green against the task's success criteria.

## Paths the agent must respect
- `app/` source · `tests/` tests · `migrations/` schema · `openspec/` specs.
- Do not touch `migrations/` history; add new migrations only.
