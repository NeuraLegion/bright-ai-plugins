---
name: run-scan
description: Select Bright security tests, run scans against registered entrypoints, monitor execution, and retrieve findings.
---

## Run Security Scans

### Step 1: Select the test set

Call `listTests` and select from its response. It returns every test the connected Bright
cluster supports, each with a `tag`, a `description`, server-assigned `buckets` (such as `api`,
`server_side`, `client_side`, `business_logic`, `mcp_attacks`), and `enabled`, `deprecated`,
and `mutuallyExclusive` flags.

1. Drop tests that are `deprecated` or not `enabled`.
2. Narrow by `buckets` to what the target actually is. An HTTP API draws on `api` and
   `server_side`; a rendered web UI adds `client_side`; an MCP server adds `mcp_attacks`.
3. Within that shortlist, match each test's own `description` against what the endpoint group
   does — where it takes input, whether it renders templates, accepts uploads, executes
   commands, reaches other services, or is the authentication surface itself.
4. Give any test flagged `mutuallyExclusive` a scan of its own — it cannot share one with
   other tests.

Do not scan from a remembered list of tags. Bright ships far more tests than any fixed mapping
would name and the catalogue changes between releases, so a hardcoded list silently narrows the
scan to a fraction of the product. In particular, an API surface scanned without the
access-control and object-authorization tests in the `api` and `business_logic` buckets will
miss the most common API vulnerability classes.

Keep the set as small as it can be while still covering the endpoint group. Do not include
destructive or special-case tests unless the user explicitly asks for them.

### Step 2: Group scan work

Group entrypoints by equivalent test set so the scan plan stays compact and easy to reuse.

For each group, record the configuration below. A later validation scan has to reproduce it
exactly to prove a fix worked, so this is the baseline the remediation loop reuses — not a
restatement of the tool schema:
- `entrypointIds`
- `tests`
- attack locations (body, query, path, or headers)
- `authObjectId`
- `repeaters`

### Step 3: Launch scans

Call `runScan` once per group, in the project resolved in `setup-repeater`, using that group's
recorded configuration.

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
