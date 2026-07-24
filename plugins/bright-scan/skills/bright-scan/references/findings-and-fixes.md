# Findings & fixes

How to turn Bright vulnerabilities into fix tasks.

## Retrieving findings

- MCP: `listScanVulnerabilities` (list) → `getScanVulnerability` (detail, evidence, reproduction).
- CLI/platform: review in the [Bright app](https://app.brightsec.com/scans) or export a report
  (https://docs.brightsec.com/docs/exporting-a-scan).

Each vulnerability includes at least: name/type, severity, the affected entrypoint (method + URL),
the vulnerable parameter, evidence, and remediation guidance. Use `getScanEntrypoint` to see the
exact request/response that triggered it.

## Severity & priority

Order fix tasks by **severity**, then by **exploitability**. Bright severities:

| Severity | Meaning | Action |
|----------|---------|--------|
| Critical | Directly exploitable, high impact (e.g. SQLi, RCE, auth bypass) | Fix immediately, block release |
| High | Serious, exploitable under common conditions | Fix before merge |
| Medium | Requires specific conditions or lower impact | Fix soon |
| Low | Hardening / defense-in-depth | Batch |

Within a severity, prioritize injection and access-control findings (SQLi, OS command injection,
SSRF, IDOR/BAC, XXE) ahead of information-disclosure and header findings.

## Fix-task format

For each finding, produce a task:

```
[<severity>] <vuln type> at <METHOD> <path>
  Parameter : <injectable param / location>
  Evidence  : <one-line summary of proof from getScanVulnerability>
  Fix       : <concrete code change — parameterize query, encode output, add authz check, …>
  Verify    : rescan entrypoint <id> (runScan entrypointStatuses ["vulnerable"] / bright-cli scan:retest)
```

## Common findings — fix at a glance

| Finding | Root cause | Minimal fix |
|---------|-----------|-------------|
| SQL Injection | Untrusted input concatenated into SQL | Parameterized queries / prepared statements |
| Reflected/Stored XSS | Unescaped user input in HTML | Context-aware output encoding; CSP as defense-in-depth |
| Broken Access Control / IDOR | Missing per-object authorization | Enforce ownership/role checks server-side |
| OS Command Injection | Input passed to a shell | Avoid shell; use argument arrays; validate/allowlist |
| SSRF | Server fetches a user-supplied URL | Allowlist hosts; block internal ranges/metadata IPs |
| XXE | XML parser resolves external entities | Disable DTD/external entity resolution |
| Misconfigured Security Headers | Missing/weak headers | Set CSP, X-Content-Type-Options, HSTS, etc. |
| Missing HttpOnly/Secure cookie flags | Cookie flags not set | Set `HttpOnly`, `Secure`, `SameSite` |

Full vulnerability catalog: https://docs.brightsec.com/docs/vulnerabilities-index

## Verification

A fix is done only after a rescan of the affected entrypoint reports the finding resolved. Re-verify
with `runScan` (`entrypointStatuses: ["vulnerable"]`) or `bright-cli scan:retest <SCAN_ID>`. Bright
also supports auto-resolve for some test types
(https://docs.brightsec.com/docs/auto-resolve-vulnerablities).
