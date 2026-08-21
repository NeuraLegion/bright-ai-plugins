---
name: fix-and-validate
description: Apply minimal fixes for Bright findings and verify them by re-running the same scan configuration over the same target surface.
---

## Fix and Validate

### Prerequisite: a way to get fixes into the target

Every round below ends in a validation scan, which only means anything if the edited code is
what the target is running. Establish how a fix reaches the target before starting — restarting
a local process or container, or a rebuild-and-redeploy command the user supplied and authorized.

If there is no such path, this skill cannot complete a round: the comparison in step 6 has
nothing to compare. Report that instead of running rounds whose results are not evidence.

### Working model

Track findings by the key `{finding.name}::{method}::{url}`.

- New finding: first appearance of the key.
- Persistent finding: the same key appears after a remediation round.
- Fixed finding: the key disappears after a validation round.

### Round structure

Run up to 5 rounds.

#### 1. Triage findings

1. Group findings by root cause.
2. Prioritize critical and high severity findings first.
3. Prefer fixes that remove multiple findings through one safe change.

#### 2. Trace source to sink

For each finding:

1. Identify the endpoint handler.
2. Follow request data through the code path.
3. Identify the dangerous sink.
4. Confirm the smallest safe place to enforce validation, encoding, parameterization, or policy.

#### 3. Apply minimal fixes

Preferred strategies:

| Vulnerability | Fix strategy |
|---------------|--------------|
| SQL injection | Parameterize queries. Remove string concatenation. |
| XSS | Encode on output and sanitize at the boundary when needed. |
| SSRF | Allowlist destinations and block private address space. |
| Command injection | Remove shell interpretation or allowlist arguments. |
| Path traversal | Resolve paths and enforce an approved base directory. |
| Open redirect | Restrict to relative paths or an explicit allowlist. |
| Missing headers or cookie flags | Add them centrally in middleware or framework config. |

Do not leave placeholder code, fake guards, or broad speculative refactors.

#### 4. Get the fix into the running target

1. Apply the path established at the start — restart the local process or container, or run the
   user's rebuild-and-redeploy command. Restarting is not enough where the target runs a built
   artifact: it has to be rebuilt and rolled out, or the scan re-tests the old code.
2. Confirm the running target actually carries the change. A redeploy that silently failed is
   indistinguishable from a fix that did not work, and costs a scan to find out.
3. Verify health.
4. Re-verify auth when the route surface requires it.

#### 5. Re-run the same validation scan

Use the same:
- `entrypointIds`
- `tests`
- attack locations (body, query, path, or headers)
- `authObjectId`
- `repeaters`

Only narrow or adjust this baseline when the previous scan configuration is now invalid for
an explicit, documented reason.

#### 6. Compare results

1. Mark disappeared findings as fixed.
2. Keep persistent findings in the next open set.
3. Stop early when no open findings remain.

### Output

Return:
- how fixes reached the target, or that they could not
- rounds completed
- fixes applied
- findings fixed after validation
- fixes written but not validated, labelled as unverified rather than fixed
- findings still open
- blockers that prevented safe automatic remediation
