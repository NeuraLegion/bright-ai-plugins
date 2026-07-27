# Bright Security — GitHub Copilot

Bright DAST agents and skills, packaged for GitHub Copilot (coding agent).

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

- `BRIGHT_TOKEN` — Bright API token, a **secret** (referenced as `${{ secrets.BRIGHT_TOKEN }}` in agent frontmatter)

Also add a repository/organization **variable** `BRIGHT_HOSTNAME` (e.g. `app.brightsec.com`),
referenced as `${{ vars.BRIGHT_HOSTNAME }}` in the agent frontmatter. Allowlist your Bright
hostname under **Copilot → Cloud agent → Internet access → Custom allowlist**.

## Notes
- The agent frontmatter builds the MCP URL from `${{ vars.BRIGHT_HOSTNAME }}`, so self-hosted
  and private clusters work by setting that variable — no need to edit the agent files.
- Only scan targets you own or are authorized to test (local, staging, or another authorized
  environment).
