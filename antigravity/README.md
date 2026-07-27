# Bright Security — Antigravity CLI

Bright DAST workflows packaged for Google's **Antigravity CLI** (`agy`), the successor to the
now-deprecated Gemini CLI.

Antigravity loads project customizations from a workspace `.agents/` directory:
- **Rules** — `.agents/AGENTS.md` (always-on constraints + workflow overview)
- **Skills** — `.agents/skills/<name>/SKILL.md` (loaded on demand)
- **MCP** — `.agents/mcp_config.json` (Bright MCP server)

Antigravity has no separate "agent" type, so the two orchestration workflows ship as skills
alongside the six step skills:

- **Orchestration skills**: `bright-application-testing`, `bright-remediation-loop`
- **Step skills**: `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`

## Required environment
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token (used by the MCP server and the Bright CLI Repeater)

```bash
export BRIGHT_HOSTNAME="app.brightsec.com"
export BRIGHT_TOKEN="your-bright-api-token"
```

## Install (workspace)
Copy the `.agents/` directory into the root of the workspace you want to scan:

```bash
cp -R antigravity/.agents  your-project/
```

Antigravity CLI (`agy`) auto-discovers `.agents/AGENTS.md`, `.agents/skills/`, and the
workspace MCP config at `.agents/mcp_config.json`.

For a **global** install (all workspaces), place the same files under `~/.gemini/config/`
(rules/skills) and add the MCP server to `~/.gemini/antigravity/mcp_config.json`.

## MCP notes
Antigravity uses `serverUrl` (not `url`/`httpUrl`) for HTTP-based MCP servers. The bundled
`mcp_config.json` uses `${BRIGHT_HOSTNAME}` / `${BRIGHT_TOKEN}`; if your Antigravity version
does not expand environment variables in the MCP config, replace them with literal values
(and edit `serverUrl` for a self-hosted/non-default cluster).

## Use
```
agy
AGY> Run a Bright DAST scan on this app and summarize findings
AGY> Scan, fix the findings, and re-verify
```

Scan any target you own or are authorized to test (local, staging, or another authorized
environment); reach private/local targets through a Bright Repeater.
