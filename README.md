# Bright AI Plugins

Bright Security DAST agents and skills, installable the **native way** into every major AI
coding tool from this single repository: Cursor, Claude Code, Codex, GitHub Copilot,
OpenCode, and Antigravity CLI.

Every package wires the **same two agents** and **six skills** to the Bright MCP server:

**Agents**
- `bright-application-testing` — analyze the repo, reach the target (local, staging, or any authorized environment), configure Bright, register attack surface, and run DAST scans (through a Repeater for private/local targets).
- `bright-remediation-loop` — run DAST, apply minimal fixes, restart, and re-run the same validation scans until findings are gone.

**Skills**
- `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`

## Install

The repo root carries one marketplace manifest per tool, so each tool installs its own
package with its own native command:

| Tool | Native install |
|------|----------------|
| **Cursor** | `cursor-agent plugin marketplace add https://github.com/NeuraLegion/bright-ai-plugins` then install **bright-security** via `/plugins` (or IDE → Customize → Plugins) |
| **Claude Code** | `claude plugin marketplace add NeuraLegion/bright-ai-plugins` then `claude plugin install bright-security@brightsec` |
| **Codex** | `codex plugin marketplace add NeuraLegion/bright-ai-plugins` then `codex plugin add bright-security@brightsec` |
| **GitHub Copilot CLI** | `copilot plugin marketplace add NeuraLegion/bright-ai-plugins` then `copilot plugin install bright-security@brightsec` (plus one `copilot mcp add` — see [`github-copilot/`](./github-copilot/)) |
| **Antigravity CLI** | `agy plugin install https://github.com/NeuraLegion/bright-ai-plugins/tree/main/antigravity` |
| **OpenCode** | clone and copy [`opencode/`](./opencode/) into your project or `~/.config/opencode/` (OpenCode has no git plugin installer — see [`opencode/`](./opencode/)) |

Marketplace manifests at the repo root:
`.cursor-plugin/marketplace.json` (Cursor), `.claude-plugin/marketplace.json` (Claude Code),
`.agents/plugins/marketplace.json` (Codex), `.github/plugin/marketplace.json` (Copilot CLI).
All four index the marketplace name `brightsec` and the plugin name `bright-security`.

## Packages

| Tool | Folder | Agents | Skills | MCP config |
|------|--------|--------|--------|------------|
| Cursor | [`cursor/`](./cursor/) | `agents/*.md` | `skills/*/SKILL.md` | `mcp.json` |
| Claude Code | [`claude-code/`](./claude-code/) | `agents/*.md` | `skills/*/SKILL.md` | `.mcp.json` |
| Codex | [`codex/`](./codex/) | as skills* | `skills/*/SKILL.md` | `.mcp.json` |
| GitHub Copilot | [`github-copilot/`](./github-copilot/) | `agents/*.agent.md` (CLI), `.github/agents/*.md` (coding agent) | `skills/*/SKILL.md` | `copilot mcp add` / agent frontmatter |
| OpenCode | [`opencode/`](./opencode/) | `.opencode/agent/*.md` | `.opencode/skills/*/SKILL.md` | `opencode.json` |
| Antigravity CLI | [`antigravity/`](./antigravity/) | as skills* | `skills/*/SKILL.md` | `mcp_config.json` |

\* Codex and Antigravity CLI have no separate agent type — the two orchestration workflows
ship as skills. Antigravity also carries always-on rules in `rules/`.

The `cursor/` package is the canonical source the other packages mirror.

## Required environment (all packages)
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token (used by the MCP server and the Bright CLI Repeater)

```bash
export BRIGHT_HOSTNAME="app.brightsec.com"
export BRIGHT_TOKEN="your-bright-api-token"
```

Each package's `README.md` has the tool-specific install steps and MCP notes (some tools
expand env vars in MCP config; Codex and Copilot need the token wired differently — the
package READMEs cover it).

## Safety
Only scan targets you own or are explicitly authorized to test — a local dev server, a
staging/QA environment, or any host you're authorized to assess. The agents ask for
confirmation before scanning a target that isn't obviously yours. Reach private or local
targets through a Bright Repeater; publicly reachable targets can be scanned directly. DAST
sends real attack traffic, so authorization is the operator's responsibility.

## License
MIT © [Bright Security](https://brightsec.com)
