#!/usr/bin/env python3
"""agentkit statusline — model · dir · git branch · context% · session cost.

Reads Claude Code's JSON session data on stdin and prints one status line.
Standard library only (no jq, no npm) — fits the Python-focused kit and starts fast.
Wire it via .claude/settings.json — see docs/CHEATSHEET.md.
"""
import json
import os
import subprocess
import sys

d = json.load(sys.stdin)

model = d.get("model", {}).get("display_name", "?")
dirname = os.path.basename(d.get("workspace", {}).get("current_dir", "")) or "?"
pct = int(d.get("context_window", {}).get("used_percentage") or 0)
cost = d.get("cost", {}).get("total_cost_usd") or 0

# Context bar, colored by usage: green < 70%, yellow 70–89%, red 90%+.
CYAN, GREEN, YELLOW, RED, RESET = "\033[36m", "\033[32m", "\033[33m", "\033[31m", "\033[0m"
color = RED if pct >= 90 else YELLOW if pct >= 70 else GREEN
filled = max(0, min(10, pct // 10))
bar = "▓" * filled + "░" * (10 - filled)

branch = ""
try:
    b = subprocess.check_output(
        ["git", "branch", "--show-current"], text=True, stderr=subprocess.DEVNULL
    ).strip()
    branch = f" | 🌿 {b}" if b else ""
except Exception:
    pass  # not a git repo, or git absent — show the rest anyway

print(f"{CYAN}[{model}]{RESET} 📁 {dirname}{branch} | {color}{bar}{RESET} {pct}% | ${cost:.2f}")
