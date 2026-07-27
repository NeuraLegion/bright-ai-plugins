# Bright Security — DAST rules for Antigravity CLI

You can run Bright Dynamic Application Security Testing (DAST) through the `brightsec` MCP
server (tools such as `listProjects`, `listRepeaters`, `createRepeater`, `addAuth`, `testAuth`,
`listEntrypoints`, `addEntrypoint`, `listTests`, `runScan`, `getScanStatus`,
`listScanVulnerabilities`, `getScanVulnerability`). The detailed workflows ship as skills in
this plugin — Antigravity loads the relevant one on demand.

## Always-on rules

- **Authorization:** only scan targets the user owns or is explicitly authorized to test — a
  local dev server, a staging/QA environment, or any host the user authorizes. If the target
  isn't obviously the user's, confirm authorization before scanning.
- **Reachability:** reach private or local targets through a Bright CLI Repeater; a publicly
  reachable target can be scanned directly (no Repeater).
- **Credentials:** require `BRIGHT_HOSTNAME` and `BRIGHT_TOKEN` before any Bright operation.
  Both are used by the MCP server and the Bright CLI Repeater. Never hardcode them.
- **Destructive endpoints:** do not fuzz `DELETE` routes, credential/identity mutation routes,
  or requests whose body mutates `password`/`newPassword`/`passwd`/email.
- **Scan config:** always pass `repeaters` as an array to `runScan`/`runDiscovery` for
  private/local targets.

## Workflows (skills)

- **Application testing** — `bright-application-testing`: analyze the repo, reach the target,
  configure Bright + Repeater, register attack surface, run scans, return findings.
- **Remediation loop** — `bright-remediation-loop`: run DAST, apply minimal fixes, restart, and
  re-run the same validation scans until findings are gone.
- **Steps** — `analyze-codebase`, `setup-repeater`, `setup-auth`, `register-entrypoints`,
  `run-scan`, `fix-and-validate`.
