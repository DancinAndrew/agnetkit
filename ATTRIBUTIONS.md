# Attributions

agentkit vendors and adapts work from three MIT-licensed projects. Their license terms
are preserved. agentkit itself is MIT (see `LICENSE`, if added).

## ECC — `affaan-m/ECC`
- License: MIT (full text in `ECC-LICENSE`).
- What is vendored: a curated subset of `agents/`, `skills/`, `rules/{common,python}/`,
  `commands/`, `contexts/`, and `mcp-configs/mcp-servers.json`, copied verbatim into
  `payload/.claude/`. Pinned commit recorded in `VERSION`.
- What is **not** vendored: all non-Python language packs, the hook runtime, and
  domain skills unrelated to backend/RAG work. See `docs/ARCHITECTURE.md`.

## Andrej Karpathy guidelines — `multica-ai/andrej-karpathy-skills`
- License: MIT.
- What is used: the four principles (Think Before Coding, Simplicity First, Surgical
  Changes, Goal-Driven Execution) form Section 1 of `CLAUDE.md`.

## OpenSpec — `Fission-AI/OpenSpec` (`@fission-ai/openspec`)
- License: MIT.
- How it is used: installed at deploy time via npm and scaffolded with `openspec init`.
  Not vendored — OpenSpec is a CLI and is meant to be installed, not copied.

---
This is an independent integration and is not affiliated with or endorsed by the authors
of ECC, the Karpathy guidelines, or OpenSpec.
