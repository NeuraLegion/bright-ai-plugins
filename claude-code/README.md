# Bright Security — Claude Code plugin

Same Bright DAST agents and skills as the Cursor plugin, packaged for Claude Code.

## Contents
- **Agents** (`agents/`): `bright-application-testing`, `bright-remediation-loop`
- **Skills** (`skills/`): `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`
- **MCP** (`.mcp.json`): Bright MCP server over HTTP

## Required environment
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token (used by the MCP server and the Bright CLI Repeater)

```bash
export BRIGHT_HOSTNAME="app.brightsec.com"
export BRIGHT_TOKEN="your-bright-api-token"
```

## Install
Copy this directory into your project as a Claude Code plugin, or reference it from a
marketplace. For a quick local install, point Claude at the directory:

```bash
claude --plugin-dir /path/to/bright-ai-plugins/claude-code
```

Then confirm the Bright MCP server is connected and the agents appear with `/agents`.

## Use
```
> Use the bright-application-testing agent to scan this app
> Use the bright-remediation-loop agent to scan, fix, and re-verify
```

The MCP server and the Repeater both read `BRIGHT_HOSTNAME` and `BRIGHT_TOKEN`. Scan any target
you own or are authorized to test (local, staging, or another authorized environment); reach
private/local targets through a Repeater.
