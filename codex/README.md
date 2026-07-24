# Bright Security — Codex plugin

Same Bright DAST workflows as the Cursor plugin, packaged for Codex.

Codex has no separate "agent" type, so the two orchestration workflows ship as skills
alongside the six step skills:

- **Orchestration skills**: `bright-application-testing`, `bright-remediation-loop`
- **Step skills**: `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`

## Required environment
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token

## Install
Add this folder as a plugin via a Codex marketplace entry, then install from the Plugins
Directory. For local development:

```bash
codex plugin marketplace add ./   # from a marketplace root that lists this plugin
```

See the Codex docs for marketplace wiring (`.agents/plugins/marketplace.json`).

## MCP
`.mcp.json` declares the Bright MCP server over HTTP. Depending on your Codex version you
may instead configure it in `~/.codex/config.toml`:

```toml
[mcp_servers.brightsec]
url = "https://app.brightsec.com/mcp"
http_headers = { Authorization = "Api-Key ${BRIGHT_TOKEN}" }
```

## Safety hook
`hooks/hooks.json` runs a `PreToolUse` guard (`scripts/validate-no-production-targets.sh`)
that blocks Bright scans/HTTP calls against anything other than localhost or `*.brightsec.com`.
Codex-bundled hooks require explicit trust on first use.
