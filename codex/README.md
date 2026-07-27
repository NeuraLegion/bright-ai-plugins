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
Add this folder as a plugin via a Codex marketplace entry, then install from the Plugins
Directory. For local development:

```bash
codex plugin marketplace add ./   # from a marketplace root that lists this plugin
```

See the Codex docs for marketplace wiring (`.agents/plugins/marketplace.json`).

## MCP
`.mcp.json` declares the Bright MCP server over streamable HTTP. Codex does **not** interpolate
`${VAR}` inside config values, so the token is wired through Codex's env mechanism
(`bearer_token_env_var`) and the URL is a literal. Bright MCP accepts both `Bearer` and
`Api-Key` schemes, so `bearer_token_env_var = "BRIGHT_TOKEN"` authenticates cleanly.

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
- **Self-hosted / non-default cluster:** edit `url` to `https://<your-BRIGHT_HOSTNAME>/mcp`
  (Codex can't expand `${BRIGHT_HOSTNAME}` here).

Equivalent `~/.codex/config.toml` if you prefer host-level config over the bundled plugin:

```toml
[mcp_servers.brightsec]
url = "https://app.brightsec.com/mcp"
bearer_token_env_var = "BRIGHT_TOKEN"
```

## Safety
Only scan targets you own or are authorized to test (local, staging, or another authorized
environment). Reach private/local targets through a Bright Repeater; public targets can be
scanned directly.
