---
name: register-entrypoints
description: Register safe endpoints in Bright with realistic requests and working auth configuration.
---

## Register Entrypoints

### Step 1: Build realistic requests

For each endpoint, construct a request with:
- a concrete URL built from `baseUrl` and the route path
- realistic path parameter values
- realistic query parameter values
- content type headers
- a non-empty request body when the endpoint expects one

Do not register empty placeholder payloads such as `{}` when the route logic clearly
expects richer input.

### Step 2: Register the endpoint in Bright

First call `listEntrypoints` and reuse a matching existing entrypoint to avoid duplicates.
Otherwise call `addEntrypoint` with:
- `projectId`
- `repeaterId` when the target is private/local
- `authObjectId` when auth is required
- `request` with method, URL, headers, and body

### Step 3: Decide whether discovery is better

If the safe route surface is large, generated, or hard to enumerate manually, switch to
`runDiscovery` with the same base URL and, for private/local targets, the active Repeater.

### Step 4: Prune bad registrations

After entrypoints are added:

1. Remove endpoints that return `404`.
2. If authenticated endpoints return `401` or `403`, go back to auth setup.
3. Keep the final active set for scan reuse.

### Output

Return:
- active entrypoint IDs with method and URL
- pruned entrypoints with reason
- discovery mode or manual registration mode used
