#!/usr/bin/env bash
#
# agentkit memory hook (SessionStart) — surface the last .agent-memory.md entry so a new
# session resumes with "where I left off" automatically, without the user typing 「繼續」.
#
# A SessionStart hook's stdout is injected into Claude's context on exit 0 (Claude Code
# hooks). This reads only; writing the memory stays with Claude (CLAUDE.md §7), because a
# dumb script can't summarize a conversation — only the model can.
#
# Wire it in .claude/settings.json (or settings.local.json) — see docs/HOOKS.md.
set -euo pipefail

MEM="${CLAUDE_PROJECT_DIR:-$PWD}/.agent-memory.md"
[ -f "$MEM" ] || exit 0   # no memory yet — nothing to surface

# Newest entry = from the last "## " heading to EOF (entries are appended newest-at-bottom).
entry="$(awk '/^## /{buf=$0 ORS; next} {buf=buf $0 ORS} END{printf "%s", buf}' "$MEM")"
[ -n "${entry//[[:space:]]/}" ] || exit 0   # file has no real entry

printf 'Last session memory (.agent-memory.md):\n\n%s\n' "$entry"
