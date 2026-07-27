# Bright Security — Claude Code plugin

Bright DAST agents and skills, packaged for Claude Code.

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
The repository root ships a `.claude-plugin/marketplace.json`, so Claude Code installs this
plugin natively:

```bash
claude plugin marketplace add NeuraLegion/bright-ai-plugins
claude plugin install bright-security@brightsec
```

(Or interactively: `/plugin marketplace add NeuraLegion/bright-ai-plugins`, then `/plugin`.)

Then confirm the Bright MCP server is connected and the agents appear with `/agents`.
Inspect what got installed with `claude plugin details bright-security@brightsec`.

## Use
```
> Use the bright-application-testing agent to scan this app
> Use the bright-remediation-loop agent to scan, fix, and re-verify
```

The MCP server and the Repeater both read `BRIGHT_HOSTNAME` and `BRIGHT_TOKEN`. Scan any target
you own or are authorized to test (local, staging, or another authorized environment); reach
private/local targets through a Repeater.
