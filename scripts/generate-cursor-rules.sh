#!/usr/bin/env bash
set -euo pipefail

# ─── Cursor Rule Generation Script ───
# Transforms canonical SKILL.md + references/*.md into Cursor .mdc format.
# Run from repo root: bash scripts/generate-cursor-rules.sh
#
# Each entry in MAPPINGS defines:
#   source_path (relative to plugins/)|output_name|cursor_description|globs (comma-separated, or empty)|alwaysApply (true|false)

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/cursor/.cursor/rules"
PLUGINS_DIR="${REPO_ROOT}/plugins"

# ─── Frontmatter Mapping Config ───
MAPPINGS=(
  "bright-scan/skills/bright-scan/SKILL.md|bright-scan|Bright DAST security scanning. Use when the user asks to run or perform a security or DAST scan, to test an app or API for vulnerabilities, or to verify a vulnerability is fixed — and proactively right after you complete a code change (feature, bugfix, refactor); \"done\" means \"done and secure\" (discover, scan, fix all reported vulnerabilities, rescan). Do NOT use for: informational questions about what Bright is or detects; querying existing findings or posture across projects (use the bright-api rule); configuring authentication only (bright-auth); or wiring CI pipelines (bright-ci).||true"
  "bright-scan/skills/bright-scan/references/mcp-tools.md|bright-scan-mcp-tools|Bright MCP tool catalog: scan tools (runScan, getScanStatus, listScanVulnerabilities, getScanVulnerability, getScanEntrypoint), discovery tools (runDiscovery, uploadApiDefinition, listEntrypoints), entrypoint CRUD, auth tools, and projects/tests/repeaters. Use when calling Bright MCP tools to drive a scan.||false"
  "bright-scan/skills/bright-scan/references/cli-reference.md|bright-scan-cli|Bright CLI reference (bright-cli / @brightsec/cli): install, repeater activation, discovery:run, scan:run flags (--smart, --crawler, --project, --repeater), scan:polling, scan:retest, config files. Use for shell-driven scans and CI runtimes.||false"
  "bright-scan/skills/bright-scan/references/findings-and-fixes.md|bright-scan-findings|Bright findings reference: retrieving vulnerabilities (listScanVulnerabilities/getScanVulnerability), severity ordering, agentic fix-task format, common findings quick reference (SQLi, XSS, IDOR/BAC, command injection, SSRF, XXE, security headers, cookie flags), and rescan verification.||false"
  "bright-api/skills/bright-api/SKILL.md|bright-api|Use when querying the Bright platform for security reporting, findings analysis, or posture — read-only. Triggers include \"security posture\", \"show me findings\", \"what vulnerabilities do we have\", \"which projects need attention\", \"what changed since the last scan\", scan history. Uses Bright MCP read tools (listProjects, listScans, listVulnerabilities, listScanVulnerabilities). Do NOT use for running scans (bright-scan), configuring auth (bright-auth), or CI wiring (bright-ci).||false"
  "bright-api/skills/bright-api/references/reporting-recipes.md|bright-api-recipes|Bright reporting recipes: org posture summary, project deep dive (scans -> vulnerabilities -> detail), stale-project detection, scan diff (what changed), and coverage/connectivity checks. Pre-built compositions of Bright MCP read tools.||false"
  "bright-auth/skills/bright-auth/SKILL.md|bright-auth|Use when a scan under-covers because endpoints require login, or the user wants to configure/debug Bright authentication — \"set up auth for Bright\", \"my scan can't log in\", \"configure authentication\". Covers header/bearer, form login, OAuth/OIDC, NTLM, OTP, and multi-step flows via addAuth/editAuth/testAuth/listAuths, then validates with testAuth before scanning. Do NOT use for running scans (bright-scan), reporting (bright-api), or CI (bright-ci).||false"
  "bright-ci/skills/bright-ci/SKILL.md|bright-ci|Use when the user wants to WIRE Bright into a CI/CD pipeline config — \"set up Bright in CI\", \"add Bright to my pipeline\", \"scan in CI\", \"configure github actions / gitlab / jenkins / circleci for Bright\". Provider-agnostic: detects the CI system, edits the pipeline file in place to add a bright-cli scan job, and prompts for BRIGHT_TOKEN secret storage. Defers local-scan concerns to bright-scan. Do NOT trigger for docs-only changes, informational CI questions, or running a local scan (that is bright-scan).|.github/workflows/**,.gitlab-ci.yml,Jenkinsfile*,.circleci/config.yml,azure-pipelines*.yml,bitbucket-pipelines.yml,.travis.yml|false"
  "bright-lab/skills/bright-lab/SKILL.md|bright-lab|Use when the user asks to create a vulnerable app, scaffold a DAST test target, or build a lab for Bright — a controlled target to reproduce a vulnerability class or demo a scan. Produces a themed, Docker-packaged, intentionally vulnerable app with a documented vulnerability inventory. NOT autonomous. Do NOT use to add vulnerabilities to real/production code — output is throwaway test infrastructure that must never be deployed publicly.||false"
)

# ─── Generate ───

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}"/*.mdc

error_count=0

for mapping in "${MAPPINGS[@]}"; do
  IFS='|' read -r source_path output_name description globs always_apply <<< "${mapping}"

  source_file="${PLUGINS_DIR}/${source_path}"

  if [[ ! -f "${source_file}" ]]; then
    echo "ERROR: Source file not found: ${source_file}" >&2
    error_count=$((error_count + 1))
    continue
  fi

  output_file="${OUTPUT_DIR}/${output_name}.mdc"

  # Strip any existing YAML frontmatter from the source body
  body=$(awk '
    BEGIN { in_frontmatter=0; past_frontmatter=0 }
    /^---$/ && !past_frontmatter { in_frontmatter = !in_frontmatter; if (!in_frontmatter) { past_frontmatter=1 }; next }
    in_frontmatter { next }
    { past_frontmatter=1; print }
  ' "${source_file}")

  # Build globs YAML
  globs_yaml=$'\nglobs:'
  if [[ -n "${globs}" ]]; then
    IFS=',' read -ra glob_array <<< "${globs}"
    for g in "${glob_array[@]}"; do
      globs_yaml="${globs_yaml}"$'\n'"  - \"${g}\""
    done
  fi

  cat > "${output_file}" <<FRONTMATTER
---
description: >
  ${description}${globs_yaml}
alwaysApply: ${always_apply:-false}
---
${body}
FRONTMATTER

  echo "Generated: ${output_file##*/}"
done

if [[ ${error_count} -gt 0 ]]; then
  echo "ERROR: ${error_count} source file(s) not found. See errors above." >&2
  exit 1
fi

echo "Done. Generated $(ls "${OUTPUT_DIR}"/*.mdc 2>/dev/null | wc -l | tr -d ' ') Cursor rules in ${OUTPUT_DIR}/"
