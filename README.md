# Bright Agent Skills

Your agent writes the code. Nothing checks if it's exploitable.

Bright agent skills fix that. Install once and your coding agent can discover your app's
entrypoints, run a [Bright](https://brightsec.com) DAST scan against your live app, parse the
findings, and fix what it found — all in the same session.

**Your AI coding agent is also your security team.** These skills teach your agent to find
security vulnerabilities as you build, report your security posture across projects, and help you
fix what it finds — without leaving your workflow.

Works with **Claude Code**, **Codex**, **Gemini CLI**, **GitHub Copilot**, **OpenCode**, and
**Cursor**, and anywhere the [Agent Skills standard](https://agentskills.io) is supported.

---

## Five Skills, One Security Workflow

### [bright-scan](./plugins/bright-scan/) — Scan & Fix
Discovers entrypoints, runs a Bright scan against your running app/API, parses vulnerabilities, and
turns them into prioritized fix tasks — then rescans to confirm. Uses the Bright MCP server or the
Bright CLI.

```
Code changes → Start app/API → Discover entrypoints → Run scan → Parse vulnerabilities → Fix → Rescan
```

### [bright-api](./plugins/bright-api/) — Report & Analyze
Queries the Bright platform for your security posture across all projects. Read-only.

```
Question → Authenticate → Query platform → Present results → Suggest next actions
```

### [bright-auth](./plugins/bright-auth/) — Reach Protected Endpoints
Creates and validates Bright authentication objects so scans can reach authenticated routes.

```
Identify auth pattern → Build auth object → testAuth → Attach to discovery/scan
```

### [bright-ci](./plugins/bright-ci/) — Wire It Into CI
Detects your CI provider and writes a Bright scan job into the pipeline. Provider-agnostic.

```
Local scan works → Detect CI provider → Store BRIGHT_TOKEN → Write pipeline → Verify
```

### [bright-lab](./plugins/bright-lab/) — Seed a Vulnerable Target
Scaffolds intentionally vulnerable, Docker-packaged test apps as isolated DAST targets. For labs
and demos only — never deploy publicly.

---

## Quick Start

### 1. Get your API key
Create an organization or personal API key in the [Bright app](https://app.brightsec.com) with the
`bot`, `scans:run`, and `scans:read` scopes.

```bash
export BRIGHT_TOKEN=<your-api-key>
```

### 2. Install for your platform

Pick your AI coding tool below. Every install is one of three shapes: a **plugin marketplace**
(Claude, Codex), a **native extension install** (Gemini), or **copy files into a discovery folder**
(Copilot, OpenCode, Cursor — handled by `scripts/install.sh`).

<details open>
<summary><strong>Claude Code</strong></summary>

Add the marketplace (Claude reads `.claude-plugin/marketplace.json` from the repo root), then
install the umbrella plugin:

```
/plugin marketplace add NeuraLegion/bright-agent-skills
/plugin install bright@brightsec
```

`bright@brightsec` installs `bright-scan` + `bright-api` + `bright-auth` + `bright-ci`. Install
individual skills instead:

```
/plugin install bright-scan@brightsec
/plugin install bright-api@brightsec
/plugin install bright-auth@brightsec
/plugin install bright-ci@brightsec
/plugin install bright-lab@brightsec
```

Manage with `/plugin` (list, enable/disable, update). To test before pushing to GitHub, point the
marketplace at a local clone: `/plugin marketplace add /path/to/bright-agent-skills`.

</details>

<details>
<summary><strong>Codex</strong></summary>

```
/plugin marketplace add NeuraLegion/bright-agent-skills
/plugin install bright-scan@brightsec
/plugin install bright-api@brightsec
/plugin install bright-auth@brightsec
/plugin install bright-ci@brightsec
/plugin install bright-lab@brightsec
```

If your Codex version supports umbrella dependency auto-install, `/plugin install bright@brightsec`
installs the default set in one command.

</details>

<details>
<summary><strong>Gemini CLI</strong></summary>

Install straight from the GitHub URL:

```bash
gemini extensions install https://github.com/NeuraLegion/bright-agent-skills
```

Gemini reads `gemini-extension.json` and discovers skills under `skills/`. Update later with
`gemini extensions update brightsec`.

</details>

<details>
<summary><strong>GitHub Copilot</strong></summary>

Clone and copy the skills into the Copilot discovery folder (`-L` dereferences the repo's internal
symlinks so the copies are standalone):

```bash
git clone https://github.com/NeuraLegion/bright-agent-skills.git
bash bright-agent-skills/scripts/install.sh --platform copilot --target .
```

This installs the five skills into `.agents/skills/`. Confirm they appear under **GitHub Copilot →
Configure Skills** in VS Code. For a global install available to all repos, target your home
directory: `--target ~`.

</details>

<details>
<summary><strong>OpenCode</strong></summary>

Skills are auto-discovered from `.opencode/skills/`. Clone and copy (`-L` dereferences the repo's
internal symlinks):

```bash
git clone https://github.com/NeuraLegion/bright-agent-skills.git

# Project-local (this repo only):
mkdir -p .opencode/skills
cp -rL bright-agent-skills/.opencode/skills/* .opencode/skills/

# Global (all projects):
mkdir -p ~/.config/opencode/skills
cp -rL bright-agent-skills/.opencode/skills/* ~/.config/opencode/skills/
```

</details>

<details>
<summary><strong>Cursor</strong></summary>

The installer copies generated rules (`.cursor/rules/`) and native skills (`.cursor/skills/`) into
your project:

```bash
git clone https://github.com/NeuraLegion/bright-agent-skills.git
bash bright-agent-skills/scripts/install.sh --platform cursor --target .
```

```powershell
# Windows: run the equivalent copy steps, or use WSL/Git Bash to run install.sh
```

For a global install available to every project, target your home directory: `--target ~`.

</details>

### 3. Connect a runtime (required)

The skills teach your agent *how* to use Bright — they still need Bright itself. Set your key once:

```bash
export BRIGHT_TOKEN=<your-api-key>   # scopes: bot, scans:run, scans:read
```

Then pick **one** runtime. `bright-scan` prefers MCP and falls back to the CLI.

**Option A — Bright MCP server (recommended for agentic use).** Point your MCP client at the Bright
endpoint (default `https://app.brightsec.com/mcp`, adjust for your cluster) and authenticate with
your API key. Typical client config:

```jsonc
{
  "mcpServers": {
    "brightsec": {
      "type": "http",
      "url": "https://app.brightsec.com/mcp",
      "headers": { "Authorization": "Bearer ${BRIGHT_TOKEN}" }
    }
  }
}
```

Client-specific setup: [VSCode](https://docs.brightsec.com/docs/configure-in-vscode) ·
[Augment Code](https://docs.brightsec.com/docs/configure-bright-mcp-in-augment-code) ·
[MCP tools reference](https://docs.brightsec.com/docs/bright-mcp-tools). MCP config file locations
differ per tool (e.g. Cursor `.cursor/mcp.json`, Claude Code `~/.claude.json` / project config).

**Option B — Bright CLI.**

```bash
npm install @brightsec/cli -g
bright-cli --version
```

For local/private targets, register and activate a [Repeater](https://docs.brightsec.com/docs/on-premises-repeater-local-agent).

### 4. Try it
```
> "Scan my API for security vulnerabilities"
> "What's my security posture across all projects?"
> "Set up Bright in my GitHub Actions pipeline"
```

---

## How It Works

These are [Agent Skills](https://agentskills.io) — structured markdown that teaches AI coding agents
domain-specific workflows. No runtime dependencies are installed and no code runs in the background;
the skills drive the Bright MCP server or the Bright CLI.

One canonical source, many platform adapters:

```
plugins/
├── bright-scan/   skills/bright-scan/  SKILL.md + references/ (mcp-tools, cli, findings)
├── bright-api/    skills/bright-api/   SKILL.md + references/ (reporting recipes)
├── bright-auth/   skills/bright-auth/  SKILL.md
├── bright-ci/     skills/bright-ci/    SKILL.md
├── bright-lab/    skills/bright-lab/   SKILL.md
└── bright/        umbrella (installs scan + api + auth + ci)
skills/            Symlinks for Gemini/Copilot discovery → plugins/
.opencode/skills/  Symlinks for OpenCode discovery → plugins/
.cursor/skills/    Symlinks for Cursor native skills → plugins/
cursor/            Generated Cursor .mdc rules (do NOT edit by hand)
scripts/           generate-cursor-rules.sh, install.sh, bump-version.sh
```

### Platform Support

| Platform | Install method | Manifest |
|----------|----------------|----------|
| Claude Code | `/plugin install` | `.claude-plugin/marketplace.json` + `plugins/*/.claude-plugin/plugin.json` |
| Codex | `/plugin install` | `.codex-plugin/marketplace.json` + `plugins/*/.codex-plugin/plugin.json` |
| Gemini CLI | `gemini extensions install` | `gemini-extension.json` |
| GitHub Copilot | `install.sh --platform copilot` | none — discovers via `skills/` symlinks |
| OpenCode | copy to `.opencode/skills/` | none — auto-discovered |
| Cursor | `install.sh --platform cursor` | generated `cursor/.cursor/rules/` + `.cursor/skills/` |

---

## Security

Never hardcode `BRIGHT_TOKEN`. Always use an environment variable or your CI secret store. DAST
sends real attack traffic — only scan targets you own or are explicitly authorized to test. For
local/private targets, use a [Repeater](https://docs.brightsec.com/docs/on-premises-repeater-local-agent)
rather than exposing them to the internet.

## Resources
- [Bright Documentation](https://docs.brightsec.com/)
- [Bright MCP Tools](https://docs.brightsec.com/docs/bright-mcp-tools)
- [Bright CLI](https://docs.brightsec.com/docs/about-bright-cli)
- [Vulnerabilities Index](https://docs.brightsec.com/docs/vulnerabilities-index)
- [Agent Skills Specification](https://agentskills.io)

## License
MIT © [Bright Security](https://brightsec.com)
