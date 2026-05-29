# Hooks: why they're not vendored

The original plan was to vendor ECC's `memory-persistence` and `strategic-compact` hooks as
an opt-in extra. After inspecting the actual code, that turned out to be the wrong call.
Here's the honest reasoning, so you can decide for yourself.

## What I found

ECC's production hook graph (`hooks/hooks.json`) is **coupled to ECC's native plugin
install layout**:

- Every hook command is an inline `node -e "..."` **plugin-root resolver** that hunts for
  `~/.claude/plugins/ecc/...`, `~/.claude/plugins/cache/ecc/<org>/<version>/...`, etc.
- The SessionStart hook (`session-start-bootstrap.js`) does **not** do the work itself — it
  resolves the plugin root and then spawns `run-with-flags.js → session-start.js`, gated by
  a hook-profile/flags system.
- The stateful pieces (`session-manager.js`, `state-store/`) pull in native-ish deps
  (`sql.js`, `ajv`) and a sizeable `scripts/lib/` tree.

The only genuinely standalone script is `pre-compact.js` (a compaction logger). But a
"save state on compaction" hook with no working SessionStart **loader** is half a system —
it writes context nobody reads back. Not worth it.

## The decision

Vendoring this standalone would mean copying a large, tightly-coupled script tree and then
rewriting its path resolution — fragile, and a direct violation of the Simplicity-First
principle this kit is built around. So:

- **agentkit ships hook-free.** This also matches a low-context / local-model friendly
  default.
- If you want ECC's hooks, install them **the way they're designed to be installed**:
  natively, as the ECC plugin.

## How to add ECC hooks natively (optional)

Hooks are the one ECC surface best obtained from ECC itself. From Claude Code:

```
/plugin marketplace add https://github.com/affaan-m/ECC
/plugin install ecc@ecc
```

This gives you ECC's hooks (memory persistence, strategic compaction, continuous-learning
signals) with their resolver and script tree intact.

> Coexistence caveat: the ECC plugin also ships agents/skills/commands that overlap with
> agentkit's vendored copies. To avoid duplicate surfaces, if you install the full ECC
> plugin for its hooks, consider removing the overlapping vendored copies from your
> project `.claude/` (or vice-versa). Don't run both the plugin **and** ECC's
> `install.sh --profile full` — that double-install is ECC's most common breakage.

## If you really want a minimal home-grown memory hook

Simplest reliable version: a `SessionEnd` hook that appends a short summary to
`./.agent-memory.md`, and a `SessionStart` hook that prints the last N lines back. ~30 lines
of Node, no dependencies, no resolver. Ask and it can be added as a clearly-scoped,
self-contained extra — but it is deliberately not part of the default kit.
