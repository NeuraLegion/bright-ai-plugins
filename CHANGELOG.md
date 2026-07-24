# Changelog

All notable changes to Bright Agent Skills are documented here.

## [0.1.0] — Unreleased

Initial scaffold.

### Added
- Multi-platform skill repository serving Claude Code, Codex, Gemini CLI, GitHub Copilot, OpenCode,
  and Cursor from one canonical source.
- `bright-scan` — DAST scanning loop (discover → scan → parse → fix → rescan) with references for
  the Bright MCP tool catalog, Bright CLI, and findings/fixes.
- `bright-api` — read-only platform posture and findings reporting, with reporting recipes.
- `bright-auth` — authentication object configuration and validation.
- `bright-ci` — provider-agnostic CI/CD pipeline wiring.
- `bright-lab` — intentionally-vulnerable DAST target scaffolder.
- `bright` — umbrella plugin installing scan + api + auth + ci.
- Platform adapters: Claude/Codex marketplace manifests, Gemini extension manifest, symlink-based
  discovery for Copilot/OpenCode/Cursor, and generated Cursor `.mdc` rules.
- Tooling: `generate-cursor-rules.sh`, `install.sh`, `bump-version.sh` + `.version-bump.json`.
