# Bright Security — Antigravity CLI

Bright DAST workflows packaged as a native plugin for Google's **Antigravity CLI** (`agy`),
the successor to the now-deprecated Gemini CLI.

This directory is an Antigravity plugin:

- **`plugin.json`** — plugin manifest (required marker)
- **Skills** — `skills/<name>/SKILL.md` (loaded on demand)
- **MCP** — `mcp_config.json` (Bright MCP server)
- **Rules** — `rules/bright-security.md` (always-on constraints + workflow overview)

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

## Install (native)

`agy plugin install` accepts a GitHub URL with a subpath:

```bash
agy plugin install https://github.com/NeuraLegion/bright-ai-plugins/tree/main/antigravity
```

Or from a local clone:

```bash
git clone https://github.com/NeuraLegion/bright-ai-plugins.git
agy plugin install ./bright-ai-plugins/antigravity
```

The plugin lands in `~/.gemini/config/plugins/bright-security/` and its skills and MCP server
are discovered automatically. Verify with `agy plugin list` (components: `skills`,
`mcpServers`) and `agy plugin validate ./antigravity` before installing if you've modified it.

## MCP notes
Antigravity uses `serverUrl` (not `url`/`httpUrl`) for HTTP-based MCP servers. The bundled
`mcp_config.json` uses `${BRIGHT_HOSTNAME}` / `${BRIGHT_TOKEN}`; if your Antigravity version
does not expand environment variables in the MCP config, replace them with literal values
(and edit `serverUrl` for a self-hosted/non-default cluster).

## Rules note
`rules/bright-security.md` is copied with the plugin, but `agy plugin list` reports only
`skills` and `mcpServers` as imported components. If the always-on rules don't take effect in
your version, copy the file into your workspace rules (e.g. append it to the workspace
`AGENTS.md`).

## Use
```
agy
AGY> Run a Bright DAST scan on this app and summarize findings
AGY> Scan, fix the findings, and re-verify
```

Scan any target you own or are authorized to test (local, staging, or another authorized
environment); reach private/local targets through a Bright Repeater.
