# Bright Security — GitHub Copilot

Same Bright DAST agents and skills as the Cursor plugin, packaged for GitHub Copilot
(coding agent).

## Contents
- **Custom agents** (`.github/agents/`): `bright-application-testing`, `bright-remediation-loop` — each declares the Bright MCP server in its `mcp-servers` frontmatter.
- **Skills** (`.agents/skills/`): `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`.

## Install
Copy both folders to the root of the target repository:

```bash
cp -R github-copilot/.github  your-repo/
cp -R github-copilot/.agents  your-repo/
```

Custom agents are discovered from `.github/agents/`; skills from `.agents/skills/` (confirm
under **GitHub Copilot → Configure Skills** in VS Code).

## Required secrets (Copilot environment)
Add these to the repository's **`copilot`** GitHub Actions environment (repo/org secrets are
not visible to Copilot agents):

- `BRIGHT_TOKEN` — Bright API token (used by the Bright MCP server; referenced as `${{ secrets.BRIGHT_TOKEN }}` in agent frontmatter)
- `BRIGHT_HOSTNAME` — Bright cluster hostname, e.g. `app.brightsec.com`

Allowlist your Bright hostname under **Copilot → Cloud agent → Internet access → Custom
allowlist**.

## Notes
- The agent frontmatter hardcodes `https://app.brightsec.com/mcp`. For a self-hosted/private
  cluster, edit the `url` in each agent to your `BRIGHT_HOSTNAME`.
- Scans target `localhost` in the agent's execution environment only.
