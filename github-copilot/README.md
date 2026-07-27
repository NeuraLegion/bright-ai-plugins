# Bright Security — GitHub Copilot

Bright DAST agents and skills, packaged for GitHub Copilot — both the **Copilot CLI**
(native plugin install) and the **Copilot coding agent** on github.com (copy into the target
repo).

## Contents
- **`plugin.json`** — Copilot CLI plugin manifest
- **CLI agents** (`agents/*.agent.md`): `bright-application-testing`, `bright-remediation-loop`
- **Skills** (`skills/*/SKILL.md`): `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`, `run-scan`, `fix-and-validate`
- **Coding-agent agents** (`.github/agents/*.md`): same two agents with `mcp-servers` frontmatter using `${{ vars.BRIGHT_HOSTNAME }}` / `${{ secrets.BRIGHT_TOKEN }}`

## Copilot CLI (native install)

The repository root ships a Copilot marketplace manifest (`.github/plugin/marketplace.json`):

```bash
copilot plugin marketplace add NeuraLegion/bright-ai-plugins
copilot plugin install bright-security@brightsec
```

This installs the two agents and six skills. Then add the Bright MCP server once at user
level — Copilot CLI does **not** expand `${VAR}` placeholders inside MCP config, so use the
native `copilot mcp add` command and let your shell expand the values:

```bash
export BRIGHT_HOSTNAME="app.brightsec.com"   # or your cluster
export BRIGHT_TOKEN="your-bright-api-token"
copilot mcp add --transport http --header "Authorization: Api-Key $BRIGHT_TOKEN" \
  brightsec "https://$BRIGHT_HOSTNAME/mcp"
```

Verify: `copilot plugin list`, `copilot skill list`, `copilot mcp get brightsec`.

Use it:

```bash
copilot --agent bright-application-testing -i "Scan this app"
```

## Copilot coding agent (github.com)

Copy the coding-agent pieces to the root of the target repository:

```bash
cp -R github-copilot/.github  your-repo/          # custom agents
mkdir -p your-repo/.github/skills && cp -R github-copilot/skills/*  your-repo/.github/skills/
```

Custom agents are discovered from `.github/agents/`; skills from `.github/skills/` (also
picked up by Copilot CLI when run inside the repo).

### Required secrets (Copilot environment)
Add these to the repository's **`copilot`** GitHub Actions environment (repo/org secrets are
not visible to Copilot agents):

- `BRIGHT_TOKEN` — Bright API token, a **secret** (referenced as `${{ secrets.BRIGHT_TOKEN }}` in agent frontmatter)

Also add a repository/organization **variable** `BRIGHT_HOSTNAME` (e.g. `app.brightsec.com`),
referenced as `${{ vars.BRIGHT_HOSTNAME }}` in the agent frontmatter. Allowlist your Bright
hostname under **Copilot → Cloud agent → Internet access → Custom allowlist**.

## Notes
- The coding-agent frontmatter builds the MCP URL from `${{ vars.BRIGHT_HOSTNAME }}`, so
  self-hosted and private clusters work by setting that variable — no need to edit the agent
  files.
- Only scan targets you own or are authorized to test (local, staging, or another authorized
  environment).
