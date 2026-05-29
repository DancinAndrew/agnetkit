#!/usr/bin/env bash
#
# agentkit installer — deploy the layered AI dev workflow into a project (or globally).
#
#   ./install.sh [--scope project|global] [--target DIR] [--no-openspec] [--no-sysdoc] [--force]
#
#   --scope project   (default) install into a single project's ./.claude + ./CLAUDE.md
#   --scope global    install into ~/.claude (applies to all projects on this machine)
#   --target DIR      project root to install into (default: current directory)
#   --no-openspec     skip installing the OpenSpec CLI and running `openspec init`
#   --no-sysdoc       skip scaffolding the sysdoc/ system documentation directory
#   --force           overwrite an existing CLAUDE.md instead of writing CLAUDE.md.agentkit
#
# The ECC subset (agents/skills/rules/commands/contexts/mcp-configs) is vendored in this
# repo under payload/.claude and is copied verbatim — no network needed for that part.
# OpenSpec is installed via npm (needs node) because it is a CLI, not vendored content.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$SCRIPT_DIR/payload/.claude"
CONTRACT="$SCRIPT_DIR/CLAUDE.md"

SCOPE="project"
TARGET="$(pwd)"
DO_OPENSPEC=1
DO_SYSDOC=1
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --scope)      SCOPE="${2:-}"; shift 2 ;;
    --target)     TARGET="${2:-}"; shift 2 ;;
    --no-openspec) DO_OPENSPEC=0; shift ;;
    --no-sysdoc)  DO_SYSDOC=0; shift ;;
    --force)      FORCE=1; shift ;;
    -h|--help)    sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "[agentkit] unknown option: $1" >&2; exit 2 ;;
  esac
done

if [ ! -d "$PAYLOAD" ]; then
  echo "[agentkit] ERROR: payload not found at $PAYLOAD — run this from the agentkit repo." >&2
  exit 1
fi

case "$SCOPE" in
  project) CLAUDE_DIR="$TARGET/.claude" ;;
  global)  CLAUDE_DIR="$HOME/.claude"; TARGET="$HOME" ;;
  *) echo "[agentkit] ERROR: --scope must be 'project' or 'global'" >&2; exit 2 ;;
esac

echo "[agentkit] scope=$SCOPE  target=$TARGET"
echo "[agentkit] installing execution layer -> $CLAUDE_DIR"

mkdir -p "$CLAUDE_DIR"
# Merge-copy the vendored .claude payload (does not wipe existing user files).
cp -R "$PAYLOAD/." "$CLAUDE_DIR/"

# Place the operating contract (CLAUDE.md) without clobbering an existing one.
DEST_CONTRACT="$TARGET/CLAUDE.md"
if [ -f "$DEST_CONTRACT" ] && [ "$FORCE" -eq 0 ]; then
  cp "$CONTRACT" "$TARGET/CLAUDE.md.agentkit"
  echo "[agentkit] NOTE: $DEST_CONTRACT already exists."
  echo "[agentkit]       wrote $TARGET/CLAUDE.md.agentkit instead — merge it in by hand."
else
  cp "$CONTRACT" "$DEST_CONTRACT"
  echo "[agentkit] wrote $DEST_CONTRACT"
fi

# OpenSpec: spec layer. Installed via npm (it is a CLI), then scaffolded per project.
if [ "$DO_OPENSPEC" -eq 1 ]; then
  if command -v openspec >/dev/null 2>&1; then
    echo "[agentkit] OpenSpec already installed: $(openspec --version 2>/dev/null || echo '?')"
  elif command -v npm >/dev/null 2>&1; then
    echo "[agentkit] installing OpenSpec CLI (npm i -g @fission-ai/openspec@latest)..."
    npm install -g @fission-ai/openspec@latest
  else
    echo "[agentkit] WARNING: node/npm not found — skipping OpenSpec."
    echo "[agentkit]          install Node 20.19+, then: npm i -g @fission-ai/openspec@latest && openspec init"
    DO_OPENSPEC=0
  fi

  if [ "$DO_OPENSPEC" -eq 1 ] && [ "$SCOPE" = "project" ]; then
    if [ -d "$TARGET/openspec" ]; then
      echo "[agentkit] openspec/ already present — skipping 'openspec init'."
    else
      echo "[agentkit] scaffolding OpenSpec in $TARGET ..."
      ( cd "$TARGET" && openspec init ) || echo "[agentkit] NOTE: 'openspec init' did not complete — run it manually in $TARGET."
    fi
  elif [ "$DO_OPENSPEC" -eq 1 ]; then
    echo "[agentkit] global scope: OpenSpec is per-project — run 'openspec init' inside each project."
  fi
else
  echo "[agentkit] skipping OpenSpec (--no-openspec)."
fi

# sysdoc: system documentation layer.
if [ "$DO_SYSDOC" -eq 1 ] && [ "$SCOPE" = "project" ]; then
  if [ -d "$TARGET/sysdoc" ]; then
    echo "[agentkit] sysdoc/ already present — skipping scaffold."
  else
    echo "[agentkit] scaffolding system docs -> $TARGET/sysdoc"
    mkdir -p "$TARGET/sysdoc"
    cp "$SCRIPT_DIR/payload/sysdoc/"*.md "$TARGET/sysdoc/"
    echo "[agentkit] wrote sysdoc/OVERVIEW.md, ARCHITECTURE.md, RUNBOOK.md"
  fi
  SYSDOC_SUMMARY="$TARGET/sysdoc"
elif [ "$DO_SYSDOC" -eq 1 ]; then
  echo "[agentkit] global scope: sysdoc is per-project — run install.sh inside each project."
  SYSDOC_SUMMARY="per-project (run install.sh in each project)"
else
  SYSDOC_SUMMARY="skipped (--no-sysdoc)"
fi

if [ "$DO_OPENSPEC" -eq 0 ]; then
  SPEC_SUMMARY="skipped (--no-openspec)"
elif [ "$SCOPE" = "project" ]; then
  SPEC_SUMMARY="$TARGET/openspec"
else
  SPEC_SUMMARY="per-project (run 'openspec init')"
fi

cat <<EOF

[agentkit] done.
  Execution layer : $CLAUDE_DIR  (agents, skills, rules, commands, contexts, mcp-configs)
  Contract        : $TARGET/CLAUDE.md
  Spec layer      : $SPEC_SUMMARY
  System docs     : $SYSDOC_SUMMARY

  Next:
    1. Skim CLAUDE.md and fill in section 6 (Project-specific).
    2. Fill in sysdoc/OVERVIEW.md with your system's name and main components.
    3. Wire MCP servers from $CLAUDE_DIR/mcp-configs/mcp-servers.json into your client.
    4. Start a change:  /opsx:propose "your first feature"
    5. Hooks are intentionally NOT vendored — see docs/HOOKS.md for why and how to add ECC's natively.
EOF
