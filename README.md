# Bright AI Plugins

Bright Security DAST agents and skills, installable the **native way** into every major AI
coding tool from this single repository: Cursor, Claude Code, Codex, GitHub Copilot,
and Antigravity CLI.

Every package wires the **same two agents** and **six skills** to the Bright MCP server:

**Agents**
- `bright-application-testing` — analyze the repo, reach the target (local, staging, or any
  authorized environment), configure Bright, register attack surface, and run DAST scans
  (through a Repeater for private/local targets).
- `bright-remediation-loop` — run DAST, apply minimal fixes, restart, and re-run the same
  validation scans until findings are gone.

**Skills**
- `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`

## Packages

Each tool has its own package with native install, usage, update, and uninstall steps in its
README:

- **Cursor** — [`cursor/`](./cursor/)
- **Claude Code** — [`claude-code/`](./claude-code/)
- **Codex** — [`codex/`](./codex/)
- **GitHub Copilot** — [`github-copilot/`](./github-copilot/)
- **Antigravity CLI** — [`antigravity/`](./antigravity/)

The `cursor/` package is the canonical source the others mirror. Codex and Antigravity have no
separate agent type, so their two orchestration workflows ship as skills.

Marketplace manifests live at the repo root — `.cursor-plugin/marketplace.json`,
`.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json`,
`.github/plugin/marketplace.json` — all indexing the marketplace `brightsec` and the plugin
`bright-security`.

## Required environment (all packages)
- `BRIGHT_HOSTNAME` — Bright cluster hostname (e.g. `app.brightsec.com`)
- `BRIGHT_TOKEN` — Bright API token (used by the MCP server and the Bright CLI Repeater)

```bash
export BRIGHT_HOSTNAME="app.brightsec.com"
export BRIGHT_TOKEN="your-bright-api-token"
```

Each package's `README.md` has the tool-specific install steps and MCP notes (some tools
expand env vars in MCP config; Codex and Copilot need the token wired differently — the
package READMEs cover it).

## Safety
Only scan targets you own or are explicitly authorized to test — a local dev server, a
staging/QA environment, or any host you're authorized to assess. The agents ask for
confirmation before scanning a target that isn't obviously yours. Reach private or local
targets through a Bright Repeater; publicly reachable targets can be scanned directly. DAST
sends real attack traffic, so authorization is the operator's responsibility.

## License
MIT © [Bright Security](https://brightsec.com)
