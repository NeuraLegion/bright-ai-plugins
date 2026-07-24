# Bright Security — OpenCode plugin

Same Bright DAST agents and skills as the Cursor plugin, packaged for OpenCode.

## Contents
- **Agents** (`.opencode/agent/`): `bright-application-testing`, `bright-remediation-loop` (mode: primary)
- **Skills** (`.opencode/skills/`): `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`
- **MCP** (`opencode.json`): Bright MCP server (remote HTTP)

## Required environment
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token

## Install
Copy the contents into your project (or your global `~/.config/opencode/`):

```bash
cp -R opencode/.opencode  your-project/
cp    opencode/opencode.json your-project/    # or merge into an existing opencode.json
```

OpenCode auto-discovers agents from `.opencode/agent/` and skills from `.opencode/skills/`.
The Bright MCP server is enabled via `opencode.json` and reads `BRIGHT_HOSTNAME` / `BRIGHT_TOKEN`
through `{env:...}` substitution.

## Use
Select the `bright-application-testing` or `bright-remediation-loop` agent, or let OpenCode
load the step skills on demand. Scans target `localhost` only.
