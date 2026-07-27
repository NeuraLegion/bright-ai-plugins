# Bright AI Plugins

The Bright Security DAST agents and skills — the same set shipped in the
[Bright Cursor plugin](https://github.com/NeuraLegion/bright-cursor-plugin) — packaged for
other AI coding tools.

Every package wires the **same two agents** and **six skills** to the Bright MCP server:

**Agents**
- `bright-application-testing` — analyze the repo, reach the target (local, staging, or any authorized environment), configure Bright, register attack surface, and run DAST scans (through a Repeater for private/local targets).
- `bright-remediation-loop` — run DAST, apply minimal fixes, restart, and re-run the same validation scans until findings are gone.

**Skills**
- `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`

## Packages

| Tool | Folder | Agents | Skills | MCP config |
|------|--------|--------|--------|------------|
| Cursor | [`cursor/`](./cursor/) | `agents/*.md` | `skills/*/SKILL.md` | `mcp.json` |
| Claude Code | [`claude-code/`](./claude-code/) | `agents/*.md` | `skills/*/SKILL.md` | `.mcp.json` |
| Codex | [`codex/`](./codex/) | as skills* | `skills/*/SKILL.md` | `.mcp.json` |
| OpenCode | [`opencode/`](./opencode/) | `.opencode/agent/*.md` | `.opencode/skills/*/SKILL.md` | `opencode.json` |
| GitHub Copilot | [`github-copilot/`](./github-copilot/) | `.github/agents/*.md` | `.agents/skills/*/SKILL.md` | agent frontmatter |
| Gemini CLI | [`gemini-cli/`](./gemini-cli/) | bundled (context)** | bundled (context)** | `gemini-extension.json` |

\* Codex has no separate agent type — the two orchestration workflows ship as skills.
\*\* Gemini CLI has no agent/skill runtime — `GEMINI.md` drives the workflows and references the bundled markdown.

The `cursor/` package is the canonical source the other packages mirror.

## Required environment (all packages)
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token (used by the MCP server and the Bright CLI Repeater)

```bash
export BRIGHT_HOSTNAME="app.brightsec.com"
export BRIGHT_TOKEN="your-bright-api-token"
```

Each package's `README.md` has the tool-specific install steps.

### Install in Cursor (marketplace)

The repo root ships a `.cursor-plugin/marketplace.json`, so Cursor installs it the normal way:

```bash
cursor-agent plugin marketplace add https://github.com/NeuraLegion/bright-ai-plugins
```

Then install **Bright Security** via `/plugins` in the interactive Cursor agent, or from
**Cursor IDE → Customize → Plugins → brightsec**.

## Safety
Only scan targets you own or are explicitly authorized to test — a local dev server, a
staging/QA environment, or any host you're authorized to assess. The agents ask for
confirmation before scanning a target that isn't obviously yours. Reach private or local
targets through a Bright Repeater; publicly reachable targets can be scanned directly. DAST
sends real attack traffic, so authorization is the operator's responsibility.

## License
MIT © [Bright Security](https://brightsec.com)
