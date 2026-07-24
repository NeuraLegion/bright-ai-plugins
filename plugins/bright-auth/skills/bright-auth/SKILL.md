---
name: bright-auth
version: 0.1.0
description: >
  Create, test, and debug Bright authentication objects so discovery and scans
  can reach protected endpoints. Use when a scan under-covers because routes
  require login, when the user asks to "set up auth for Bright", "my scan
  can't log in", "configure authentication", or when wiring scanning for an app
  that has authentication. Covers bearer/header token injection, form login,
  cookie sessions, OAuth2/OIDC, and multi-step flows via the Bright MCP tools
  addAuth / editAuth / testAuth / listAuths. Do NOT use for running the scan
  itself (use bright-scan), reporting (bright-api), or CI wiring (bright-ci).
---

# Bright Auth Skill

DAST only finds what it can reach. Unauthenticated scans miss most business logic. This skill
configures a Bright authentication object and verifies it before scanning.

## Prerequisites

- `BRIGHT_TOKEN` in the environment.
- Bright MCP connected (`listAuths`, `addAuth`, `editAuth`, `testAuth`) or access to the Bright app.
- Never hardcode application credentials in source or config. Read them from the environment and
  reference them via Bright's string-interpolation syntax where supported.

## Workflow

```
Identify auth pattern → Build auth object → testAuth → Fix until verified → Attach to discovery/scan
```

1. **Identify the pattern.** Inspect the app (login route, token endpoint, session cookie, IdP).
   Map to one of the supported types below.
2. **Check for an existing config.** `listAuths` — reuse or `editAuth` rather than duplicating.
3. **Build the auth object.** `addAuth` with the type-specific fields.
4. **Validate.** `testAuth` returns a verdict with per-result evidence. Do not proceed until it
   passes — a broken auth object produces a hollow scan.
5. **Attach.** Reference the auth object when running discovery/scan (hand back to `bright-scan`).

## Supported patterns

| Pattern | Notes | Bright docs |
|---------|-------|-------------|
| Header / bearer token | Inject `Authorization: Bearer …` or custom header | https://docs.brightsec.com/docs/configure-header-authentication |
| Form login | Username/password against a login form | https://docs.brightsec.com/docs/configure-recorded-browser-based-form-authentication |
| OAuth2 / OIDC | External IdP (Auth0, Okta, Cognito, Azure AD) | https://docs.brightsec.com/docs/configure-oidc-connect-oauth |
| Custom multi-step | Scripted multi-request flows | https://docs.brightsec.com/docs/configure-custom-multi-step-authentication |
| NTLM | Windows-integrated auth | https://docs.brightsec.com/docs/configure-ntlm-authentication |
| OTP / multi-field | One-time codes / split input fields | https://docs.brightsec.com/docs/configure-otp-entry-across-multiple-input-fields |

Auth overview: https://docs.brightsec.com/docs/creating-authentication ·
Testing auth: https://docs.brightsec.com/docs/testing-authentication ·
String interpolation for secrets: https://docs.brightsec.com/docs/string-interpolation-syntax

## Guardrails

- Use a **dedicated test account**, not a real user's credentials.
- Prefer least-privilege test roles; use separate accounts to exercise access-control tests (BAC/IDOR).
- Keep credentials in environment variables or Bright secrets — never in the repo.
