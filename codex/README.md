# Bright Security — Codex plugin

Bright DAST workflows, packaged for Codex.

Codex has no separate "agent" type, so the two orchestration workflows ship as skills
alongside the six step skills:

- **Orchestration skills**: `bright-application-testing`, `bright-remediation-loop`
- **Step skills**: `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`

## Required environment
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token

## Install
The repository root ships a Codex marketplace manifest (`.agents/plugins/marketplace.json`),
so Codex installs this plugin natively:

```bash
codex plugin marketplace add NeuraLegion/bright-ai-plugins
codex plugin add bright-security@brightsec
```

Verify with `codex plugin list` and `codex mcp list` (the `brightsec` server should appear
with `BRIGHT_TOKEN` as its bearer token env var).

## MCP
`.mcp.json` bundles the Bright MCP server over streamable HTTP. Codex does **not** interpolate
`${VAR}` inside config values, so the token is wired through Codex's env mechanism
(`bearer_token_env_var`) and the URL is a literal. Bright MCP accepts both `Bearer` and
`Api-Key` schemes, so `"bearer_token_env_var": "BRIGHT_TOKEN"` authenticates cleanly.

```json
{
  "mcp_servers": {
    "brightsec": {
      "url": "https://app.brightsec.com/mcp",
      "bearer_token_env_var": "BRIGHT_TOKEN"
    }
  }
}
```

- Export your token as `BRIGHT_TOKEN` in the environment Codex runs in.
- **Self-hosted / non-default cluster:** the bundled URL is the default cloud cluster.
  Override it natively:

  ```bash
  codex mcp add brightsec --url "https://$BRIGHT_HOSTNAME/mcp" --bearer-token-env-var BRIGHT_TOKEN
  ```

## Safety
Only scan targets you own or are authorized to test (local, staging, or another authorized
environment). Reach private/local targets through a Bright Repeater; public targets can be
scanned directly.
