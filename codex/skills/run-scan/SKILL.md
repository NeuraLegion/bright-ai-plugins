---
name: run-scan
description: Select Bright security tests, run scans against registered entrypoints, monitor execution, and retrieve findings.
---

## Run Security Scans

### Step 1: Select the test set

Call `listTests` (the source of truth for tag identifiers) and map endpoint characteristics to the smallest useful Bright test set.

Suggested mapping:

| Endpoint characteristic | Bright test tags |
|------------------------|------------------|
| User input in body or query | `xss`, `stored_xss`, `sqli` |
| Path or URL parameters | `lfi`, `ssrf`, `unvalidated_redirect` |
| File upload | `file_upload` |
| Template rendering | `ssti` |
| Command execution | `osi` |
| Auth-sensitive endpoints | `jwt`, `brute_force_login` |
| All endpoints | `header_security`, `cookie_security`, `secret_tokens`, `csrf` |

Do not include destructive or special-case tests unless the user explicitly asks for them.

### Step 2: Group scan work

Group entrypoints by equivalent test set so the scan plan stays compact and easy to reuse.

For each group, record:
- `entrypointIds`
- `tests`
- attack locations (body, query, path, or headers)
- `authObjectId`
- `repeaters`

### Step 3: Launch scans

Call `runScan` with:
- `projectId`
- `entrypointIds`
- `tests`
- `repeaters` as an array
- `authObjectId` when applicable
- attack locations appropriate for the endpoint shape (body, query, path, or headers)

### Step 4: Monitor to completion

1. Poll `getScanStatus` until every scan finishes.
2. If a scan fails, verify the local app and auth flow before retrying.
3. Fetch findings with `listScanVulnerabilities` (per scan); get full detail for a finding with `getScanVulnerability`.

### Output

Return:
- launched scan groups and IDs
- final status for each scan
- finding list with severity, method, URL, evidence, and remedy
- the exact scan configuration needed for validation reruns
