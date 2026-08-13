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

### Step 2: Reuse an existing auth object when one fits

Call `listAuths` in the project resolved in `setup-repeater`. If an existing object covers the
same auth flow, verify it with `testAuth` and use it — there is nothing to create.

### Step 3: Verify the auth flow before saving anything

`testAuth` accepts an unsaved payload (`authObject`) as well as a saved object
(`authObjectId`). Iterate on the unsaved payload and call `addAuth` only once it verifies.
Creating the object first and fixing it afterwards leaves a dead auth object in the user's
project for every failed attempt.

Read the verdict explicitly: `verified=false`, or any entry in `tests[]` with `failed=true`,
means auth is not verified. Do not proceed on a partial pass.

Correct the payload from the per-result evidence the test returns. Common causes — not an
exhaustive list — are the login body shape, token extraction, header name or format, the login
endpoint path and content type, and reachability of the target (through the Repeater for
private or local targets).

Retry up to 10 times. If auth is still broken, stop and report the exact reason.

### Step 4: Save the verified auth object

Call `addAuth` with the payload that verified, in the project resolved in `setup-repeater`. Set
`repeaterRequired: true` for private or local targets, so the login itself runs through the
connected Repeater, and configure `reauthTriggers` for `401` and `403` responses.

### Output

Return:
- `authObjectId` or `null`
- auth type summary
- login endpoint used
- any assumptions or unresolved blockers
