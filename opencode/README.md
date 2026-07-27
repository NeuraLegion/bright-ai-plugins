# Bright Security — OpenCode plugin

Bright DAST agents and skills, packaged for OpenCode.

## Contents
- **Agents** (`.opencode/agent/`): `bright-application-testing`, `bright-remediation-loop` (mode: primary)
- **Skills** (`.opencode/skills/`): `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`
- **MCP** (`opencode.json`): Bright MCP server (remote HTTP)

## Required environment
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token

## Install
OpenCode's plugin installer (`opencode plugin <module>`) handles npm JavaScript modules only —
markdown agents/skills install by placing them in OpenCode's documented discovery paths.
Clone the repo and copy this package into your project:

```bash
git clone https://github.com/NeuraLegion/bright-ai-plugins.git
cp -R bright-ai-plugins/opencode/.opencode      your-project/
cp    bright-ai-plugins/opencode/opencode.json  your-project/   # or merge into an existing opencode.json
```

Or install once for all projects (global config):

```bash
cp -R bright-ai-plugins/opencode/.opencode/agent/.   ~/.config/opencode/agents/
cp -R bright-ai-plugins/opencode/.opencode/skills/.  ~/.config/opencode/skills/
# merge the "mcp" block of bright-ai-plugins/opencode/opencode.json into ~/.config/opencode/opencode.json
```

OpenCode auto-discovers agents from `.opencode/agent/` and skills from `.opencode/skills/`
(verify with `opencode agent list`). The Bright MCP server is enabled via `opencode.json` and
reads `BRIGHT_HOSTNAME` / `BRIGHT_TOKEN` through `{env:...}` substitution.

## Use
Select the `bright-application-testing` or `bright-remediation-loop` agent, or let OpenCode
load the step skills on demand. Scan any target you own or are authorized to test (local,
staging, or another authorized environment); private/local targets go through a Repeater.
