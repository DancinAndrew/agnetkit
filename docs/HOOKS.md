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

## A minimal home-grown memory hook (opt-in, shipped as a template)

agentkit ships one tiny, dependency-free hook as a **template** — not wired by default,
because hooks stay opt-in: `payload/templates/memory-hook/agentkit-memory-start.sh`. It is a
`SessionStart` hook that injects the most recent `.agent-memory.md` entry into context, so a
new session opens already knowing where you left off — no need to type 「繼續」.

> **Why only SessionStart (the read side)?** A `SessionEnd` hook *cannot* write a useful
> summary: it is a plain script that receives the raw transcript path, and summarizing a
> conversation needs the model, not `awk`. Claude Code also documents that SessionEnd hooks
> cannot add context. So the **write** stays where it belongs — with Claude, on 「收工」 /
> `/checkpoint` (CLAUDE.md §7). The hook only automates the **read**, which a script can do.

### Wire it (per project)

1. Copy the script into the project and make it executable:
   ```bash
   mkdir -p .claude/hooks
   cp ~/.agentkit/payload/templates/memory-hook/agentkit-memory-start.sh .claude/hooks/
   chmod +x .claude/hooks/agentkit-memory-start.sh
   ```
2. Register it — add this to `.claude/settings.json` (committed, team-wide) or
   `.claude/settings.local.json` (personal, matching `.agent-memory.md` being git-ignored):
   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "matcher": "startup|resume",
           "hooks": [
             { "type": "command",
               "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/agentkit-memory-start.sh" }
           ]
         }
       ]
     }
   }
   ```
   If a `hooks` key already exists, merge the `SessionStart` array rather than overwriting it.

That's the whole thing — ~12 lines of bash, no Node, no dependencies, no plugin resolver.
