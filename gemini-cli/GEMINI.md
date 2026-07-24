# Bright Security — Gemini CLI context

You can run Bright Dynamic Application Security Testing (DAST) through the `brightsec` MCP
server (tools like `listProjects`, `listRepeaters`, `createRepeater`, `addAuth`, `testAuth`,
`addEntrypoint`, `listEntrypoints`, `listTests`, `runScan`, `getScanStatus`,
`listScanVulnerabilities`, `getScanVulnerability`). Gemini CLI has no separate agent/skill runtime, so
this context file drives the same workflows the Cursor plugin ships. The full step-by-step
instructions live in the bundled markdown under `agents/` and `skills/` — read the relevant
file before executing a phase.

## Safety
- Only scan targets the user owns or is explicitly authorized to test (local, staging, or any
  authorized environment). If the target isn't obviously the user's, confirm authorization first.
- Reach private/local targets through a Bright Repeater; a public target can be scanned directly.
- Require `BRIGHT_HOSTNAME` and `BRIGHT_TOKEN` before any Bright operation. Both are used by
  the MCP server and the Bright CLI Repeater.
- Do not fuzz destructive endpoints (all `DELETE`, credential/identity mutation, or bodies
  containing `password`/`newPassword`/`passwd`).
- Always pass `repeaters` as an array when launching scans or discovery against private/local targets.

## Workflow: application testing
Follow `agents/bright-application-testing.md`, using these skills in order:
1. `skills/analyze-codebase/SKILL.md` — detect stack, find safe endpoints.
2. Start the app in the current environment; verify health; record `baseUrl`.
3. `skills/setup-repeater/SKILL.md` — select project, create/reuse a Repeater, connect it.
4. `skills/setup-auth/SKILL.md` — build a working auth object if the app needs login.
5. `skills/register-entrypoints/SKILL.md` — register safe entrypoints (or run discovery).
6. `skills/run-scan/SKILL.md` — select tests, run scans, monitor, retrieve findings.

## Workflow: remediation loop
Follow `agents/bright-remediation-loop.md`: run the baseline scan, then use
`skills/fix-and-validate/SKILL.md` for up to 5 rounds — apply the smallest safe fix, restart
the app, and re-run the same scan configuration until findings are gone.

## Output
Return detected stack + startup command, Bright project/Repeater IDs, scan groups and test
tags, findings grouped by severity and endpoint, and any blockers.
