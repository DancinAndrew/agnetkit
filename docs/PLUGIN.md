# Installing agentkit as a Claude Code plugin

agentkit can be installed as a native Claude Code plugin — but **only its execution layer**.
This page is the honest accounting of what the plugin gives you and what it can't, so you can
decide between `/plugin install` and `install.sh`.

## What the plugin ships

The `.claude-plugin/` manifest packages the **execution layer** — the one agentkit layer that
maps to Claude Code's plugin component model:

- `agents/` — the 14 subagents
- `skills/` — the 28 skills
- `commands/` — the 9 slash commands
- `output-styles/` — the `agentkit Mentor` style

That's it. One `/plugin install` and those four surfaces are live.

## What the plugin CANNOT ship — and why

agentkit is a **four-layer system** (Principles → Spec → System docs → Execution). The plugin
model carries only the bottom layer. The top three are structurally out of reach:

| agentkit layer | In the plugin? | Why not (Claude Code plugin rules) |
| :------------- | :------------: | :--------------------------------- |
| **`CLAUDE.md`** — 4 principles, routing, execution loop | ❌ | "A `CLAUDE.md` file at the plugin root is **not loaded as project context**." Plugins contribute context through skills/agents/hooks, not an always-on contract. |
| **`.claude/rules/*`** | ❌ | Rules aren't a plugin component type; they load via `CLAUDE.md` `@`-imports, which plugins don't provide. |
| **`settings.json` permissions** (allow/deny) | ❌ | A plugin's `settings.json` supports **only** the `agent` and `subagentStatusLine` keys — not `permissions`. |
| **statusline** | ❌ | The main `statusLine` key isn't supported in plugin settings (only `subagentStatusLine`). |
| **`sysdoc/` + `openspec init`** | ❌ | Project scaffolding, not plugin components — that's `install.sh`'s job. |

So `/plugin install agentkit` gives you the tools, but **not the contract, rules, permissions,
or the spec/sysdoc workflow** — and those are what make agentkit *agentkit*, not just a bag of
agents. Treat the plugin as a convenience for the execution surfaces, not a replacement for
`install.sh`.

> There's a documented workaround — "put instructions in a skill" — but a skill is loaded when
> invoked or deemed relevant, not always-on like the `CLAUDE.md` contract. We don't fake the
> contract as a skill; that would be a downgrade dressed up as parity.

## Install it

```text
/plugin marketplace add DancinAndrew/agnetkit
/plugin install agentkit@agentkit
```

Then pick the `agentkit Mentor` output style in `/config` if you want it (it ships inactive).

To validate the manifest after cloning or editing:

```bash
claude plugin validate ./payload
```

## Recommended: plugin + install.sh together, or just install.sh

- **Want the whole kit?** Run `install.sh` (the default path). It delivers all four layers.
- **Already have your own `CLAUDE.md` and just want agentkit's agents/skills/commands?** The
  plugin is for you — install it and skip the rest.
- **Want both?** Install the plugin for the execution surfaces, then run `install.sh --scope
  project` for the contract/rules/permissions/spec/sysdoc. Be aware this duplicates the
  agents/skills/commands (once from the plugin cache, once in `.claude/`); prefer one source
  to avoid duplicate suggestions.
