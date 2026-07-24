# Bright AI Plugins

The Bright Security DAST agents and skills — the same set shipped in the
[Bright Cursor plugin](https://github.com/NeuraLegion/bright-cursor-plugin) — packaged for
other AI coding tools.

Every package wires the **same two agents** and **six skills** to the Bright MCP server:

**Agents**
- `bright-application-testing` — analyze the repo, start the app, configure Bright, register safe attack surface, and run DAST scans through a Repeater.
- `bright-remediation-loop` — run DAST, apply minimal fixes, restart, and re-run the same validation scans until findings are gone.

**Skills**
- `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`

## Packages

| Tool | Folder | Agents | Skills | MCP config | Safety hook |
|------|--------|--------|--------|------------|-------------|
| Cursor | [`cursor/`](./cursor/) | `agents/*.md` | `skills/*/SKILL.md` | `mcp.json` | `hooks/hooks.json` (beforeShellExecution) |
| Claude Code | [`claude-code/`](./claude-code/) | `agents/*.md` | `skills/*/SKILL.md` | `.mcp.json` | `hooks/hooks.json` (PreToolUse) |
| Codex | [`codex/`](./codex/) | as skills* | `skills/*/SKILL.md` | `.mcp.json` | `hooks/hooks.json` (PreToolUse) |
| OpenCode | [`opencode/`](./opencode/) | `.opencode/agent/*.md` | `.opencode/skills/*/SKILL.md` | `opencode.json` | — |
| GitHub Copilot | [`github-copilot/`](./github-copilot/) | `.github/agents/*.md` | `.agents/skills/*/SKILL.md` | agent frontmatter | — |
| Gemini CLI | [`gemini-cli/`](./gemini-cli/) | bundled (context)** | bundled (context)** | `gemini-extension.json` | — |

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

## Safety
Scans target `localhost` in the current execution environment only — never production,
staging, or third-party URLs. Claude Code and Codex enforce this with a `PreToolUse` shell
hook; the other tools carry the same rule in the agent instructions.

## License
MIT © [Bright Security](https://brightsec.com)
