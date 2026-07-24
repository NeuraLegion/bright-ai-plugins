---
name: fix-and-validate
description: Apply minimal fixes for Bright findings and verify them by re-running the same scan configuration over the same target surface.
---

## Fix and Validate

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

#### 4. Restart and health-check the app

1. Restart the application.
2. Verify health.
3. Re-verify auth when the route surface requires it.

#### 5. Re-run the same validation scan

Use the same:
- `entrypointIds`
- `tests`
- `attackLocationTypes`
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
- rounds completed
- fixes applied
- findings fixed after validation
- findings still open
- blockers that prevented safe automatic remediation