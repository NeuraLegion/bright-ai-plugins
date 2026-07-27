# Bright Security — Gemini CLI extension

Bright DAST workflows, packaged as a Gemini CLI extension.

Gemini CLI has no separate agent/skill runtime, so the workflow is driven by a context file
(`GEMINI.md`) that references the bundled `agents/` and `skills/` markdown.

## Contents
- `gemini-extension.json` — extension manifest; wires the Bright MCP server over HTTP
- `GEMINI.md` — context file that orchestrates the two workflows
- `agents/`, `skills/` — the same agent/skill markdown as the other packages, for reference

## Required environment
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token

```bash
export BRIGHT_HOSTNAME="app.brightsec.com"
export BRIGHT_TOKEN="your-bright-api-token"
```

## Install
Install the extension from this directory (or its Git URL):

```bash
gemini extensions install https://github.com/NeuraLegion/bright-ai-plugins   # or a local path
```

Gemini reads `gemini-extension.json`, loads `GEMINI.md` as context, and connects the
`brightsec` MCP server using `${BRIGHT_HOSTNAME}` / `${BRIGHT_TOKEN}`.

## Use
Ask Gemini to "run a Bright DAST scan on this app" or "scan and fix findings." It follows the
workflows in `GEMINI.md`. Scan any target you own or are authorized to test (local, staging, or
another authorized environment); reach private/local targets through a Bright Repeater.
