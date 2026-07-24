# CLAUDE.md

Guidance for coding agents working in this repository.

# Bright Agent Skills

Multi-platform agent skills repo serving Claude, Codex, Gemini, Copilot, Cursor, and OpenCode from
one canonical source. Skills teach AI agents to run Bright DAST security scanning (via the Bright
MCP server or the Bright CLI) and query the Bright platform.

## Structure

- `plugins/bright-scan/` — DAST scanning skill (SKILL.md + references)
- `plugins/bright-api/` — platform reporting skill (SKILL.md + references)
- `plugins/bright-auth/` — authentication configuration skill
- `plugins/bright-ci/` — CI/CD pipeline wiring skill
- `plugins/bright-lab/` — vulnerable-target scaffolder skill
- `plugins/bright/` — umbrella; `/plugin install bright@brightsec` installs scan + api + auth + ci
- `skills/` — symlinks for Gemini/Copilot discovery (point into plugins/)
- `.opencode/skills/` — symlinks for OpenCode discovery
- `.cursor/skills/` — symlinks for Cursor native skills discovery
- `cursor/` — generated Cursor .mdc rules (do NOT edit manually)
- `scripts/generate-cursor-rules.sh` — transforms SKILL.md → Cursor .mdc format
- `scripts/install.sh` — installer for Cursor and Copilot
- `scripts/bump-version.sh` — updates all version-bearing files atomically (reads `.version-bump.json`)

## Commands

```bash
# Regenerate Cursor rules after editing any SKILL.md or references/*.md
bash scripts/generate-cursor-rules.sh

# Verify generation is idempotent (no diff = correct)
bash scripts/generate-cursor-rules.sh && git diff cursor/

# Bump version (updates VERSION + all manifests + SKILL.md frontmatter in one pass)
bash scripts/bump-version.sh --patch   # bug fixes
bash scripts/bump-version.sh --minor   # new skill or significant capability
bash scripts/bump-version.sh --major   # breaking changes

# Manual installs
bash scripts/install.sh --platform cursor  --target ~
bash scripts/install.sh --platform copilot --target ~
```

## Manifests and Versioning

`VERSION` is the single source of truth. All platform manifests must match it.

| Platform | Manifest |
|----------|----------|
| Claude | `.claude-plugin/marketplace.json` + `plugins/*/.claude-plugin/plugin.json` |
| Codex | `.codex-plugin/marketplace.json` + `plugins/*/.codex-plugin/plugin.json` |
| Gemini | `gemini-extension.json` |
| Copilot | No manifest — discovers via `skills/` symlinks |
| Cursor | Rules generated into `cursor/.cursor/rules/`; skills symlinked in `.cursor/skills/` |
| Claude (umbrella) | `plugins/bright/.claude-plugin/plugin.json` |

`.version-bump.json` lists every version-bearing file. `bump-version.sh` reads it to update all
files atomically. When adding a new plugin, add its manifests and SKILL.md there.

## Adding a New Plugin

1. Create `plugins/<name>/skills/<name>/SKILL.md` with `name:`, `version:`, `description:` frontmatter.
2. Create `plugins/<name>/.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`.
3. Add symlinks in `skills/`, `.opencode/skills/`, and `.cursor/skills/` pointing into the new plugin.
4. Add an entry to `scripts/generate-cursor-rules.sh` `MAPPINGS` (controls Cursor .mdc generation).
5. Add the new plugin to both marketplace manifests (`.claude-plugin/`, `.codex-plugin/`).
6. Add all new manifests and SKILL.md to `.version-bump.json`.
7. Run `bash scripts/bump-version.sh --minor` so the version propagates, then regenerate Cursor rules.

## Gotchas

- `cursor/` is generated output — edit the source SKILL.md, then regenerate.
- `skills/`, `.opencode/skills/`, and `.cursor/skills/` entries are symlinks, not copies — don't
  break the relative paths (`../plugins/...` for `skills/`, `../../plugins/...` for the dot dirs).
- Cursor skill `name:` must match the symlink folder name.
- SKILL.md frontmatter requires `name:`, `version:`, and `description:`.
- Never hardcode `BRIGHT_TOKEN` in any skill, reference, or generated config — always `${BRIGHT_TOKEN}`.
- The `bright-lab` skill produces intentionally vulnerable code — it is throwaway test infrastructure
  and must never be deployed to a public/shared environment.
