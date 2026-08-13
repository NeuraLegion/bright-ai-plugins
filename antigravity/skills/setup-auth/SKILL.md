---
name: setup-auth
description: Detect application authentication requirements and create a working Bright auth object for scanning the target under test.
---

## Setup Authentication

### Step 1: Detect whether auth is required

Inspect the codebase for:
- auth middleware and guards
- login or token endpoints
- bearer token, API key, session cookie, or custom header usage
- login payload shape and token extraction path

Capture:
- `requiresAuth`
- `authType`
- `loginEndpoint`
- `loginBody`
- `headerName`
- `headerTemplate`
- `tokenJsonPath`

When credentials are needed for a test login, prefer seed data, fixtures, `.env.example`,
or repository setup docs. Do not invent credentials that have no evidence in the repo.

### Step 2: Reuse or create a Bright auth object

1. Call `listAuths`.
2. Reuse an existing suitable object when it matches the same auth flow.
3. Otherwise call `addAuth` in the project resolved in `setup-repeater`. Set
   `repeaterRequired: true` for private or local targets, so the login itself runs through the
   connected Repeater.
4. Configure re-auth triggers (`reauthTriggers`) for `401` and `403` responses.

### Step 3: Stabilize the auth object

Validate the candidate auth object with `testAuth` before using it in a scan. If it fails,
retry with targeted corrections:

1. Fix the login body shape.
2. Fix token extraction.
3. Fix header format or header name.
4. Verify the login endpoint path and content type.
5. Verify the target is reachable (through the Repeater for private/local targets).

Retry up to 10 times. If auth is still broken, stop and report the exact reason.

### Output

Return:
- `authObjectId` or `null`
- auth type summary
- login endpoint used
- any assumptions or unresolved blockers
