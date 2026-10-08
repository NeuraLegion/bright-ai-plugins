---
name: register-entrypoints
description: Register the application's operations in Bright as entrypoints from its source code, with code-grounded parameter values, health checks, and named gaps; crawl only as a fallback.
---

## Register Entrypoints

Reuse the `projectId` and Repeater from `setup-repeater` and the auth map from `setup-auth`;
Step 5 says when each is attached. Every `addEntrypoint` and `editEntrypoint` runs its auth
object's full login and sends the real request to the target, so registration has side effects.
Without a user-set time, cost, or count budget, never narrow the inventory to save effort; if an
external limit stops the run, name every unprocessed operation and why.

### Step 1: Complete the inventory from the code

Start from the `analyze-codebase` inventory and its exclusions; do not redo them. Complete and
verify it from the code, recording per operation:

- the full path, including prefixes, versioning, and sub-routers mounted in middleware, and its
  auth-map group (an unmapped route goes back to `setup-auth`)
- for gRPC-gateway, the `google.api.http` mapping; request-message fields not bound to the path or
  `body` become query parameters
- every query parameter and request header this handler reads — framework accessors (e.g.
  `QueryParam(...)`, `request.args`, `req.query`, header getters) and bind/DTO tags — not a set
  copied from a neighbouring route
- the handler identity (file plus function, or RPC name) for Step 3
- if the app serves a built frontend: the JavaScript the served `index.html` references (`curl`
  the `baseUrl`), its service worker, and the chunks they load, or the build output directory
  (e.g. `dist/`). Frontend source with no bundle in the served `index.html` is a JavaScript
  coverage gap: the frontend was not built or served

Also list the surface the code cannot reveal — routes built at runtime, plugin route tables,
server-rendered pages not statically visible, parts with no source in the repository.
That list is the only input to Step 6.

### Step 2: Craft functional parameter values

Every path, query, body, and header value must pass validation and seed mutation well. Build
each request from a concrete URL on `baseUrl`, deriving every value from the code:

- **Enums and constants** — the exact member and casing (`OAUTH2`, not `oauth2`); a real key from
  an enumerated set, not `"test"`.
- **Encoded fields** — encode what the handler decodes: a JSON-decoded `value` is `"\"en\""`, not
  `"en"`.
- **Framework conventions** — e.g. gRPC-gateway Update RPCs need an `update_mask` listing the
  fields being set.
- **Types and validation** — the declared type, format hints (email, UUID, date-time, URI),
  patterns, length bounds, every required DTO field, nested object and array shapes.
- **Seeds and specs** — IDs, slugs, and foreign keys from the seeded data; `example`
  values a shipped spec provides only where the code accepts them.
- **Dependent objects** — read real IDs from the running app. Create a missing object first
  through the application's API (`curl` against `baseUrl` with the run's credentials), and a
  separate sacrificial object for every destructive operation. If you cannot, record the route
  as a gap instead of registering a guaranteed 404.

Then:

- Build one representative value set per operation; no combinatorial variants of optional
  parameters.
- Include every required parameter plus the optional ones that widen the attack surface —
  filters, search, sort, pagination, IDs, free text, file and URL fields. A GET registered without
  the query parameters its handler reads is a defect.
- Never register `{}`, `""`, `string`, `0`, or `null` placeholders where the handler expects
  richer input, and send a non-empty body wherever the endpoint expects one.
- Bright templates such as `{{entrypoint.params.query_limit}}` in a URL are fine.

### Step 3: Deduplicate by operation

Deduplication is your judgement about operations, not a method-plus-path rule. Before each
`addEntrypoint`, call `listEntrypoints` with the `projectId` and
`host: ["<host[:port] of baseUrl>"]`, narrowed by `q` (a path fragment) and `method`, and decide
whether one already covers the operation:

- One handler, RPC, or operation is one entrypoint, whatever its parameter combinations, carrying
  the union of the parameters worth mutating.
- Two transports of one handler — a gRPC-gateway RPC path and its REST mapping — are one
  operation. Keep the one exposing more mutable input (usually REST); add the other only if it
  reaches input the first cannot. A `q` + `method` lookup misses these pairs: match by handler
  identity and search the resource fragment without `method`.
- Different handlers, different method semantics on one path, or different resources stay
  distinct: `GET` and `POST` on a collection are two entrypoints, five filter variants of the
  `GET` are one.
- If one covers the operation, `editEntrypoint` it with the missing parameters or better values
  instead of adding another.

### Step 4: Decide what to register

**Static noise.** Do not register CSS, images (png, jpg, gif, svg, webp, ico), fonts (woff, woff2,
ttf, otf, eot), source maps, `manifest.json` or `*.webmanifest`, `robots.txt`, `sitemap.xml`, or
other non-executable static files. Keep JavaScript — application bundles, chunks, locale bundles,
service workers — as it can carry vulnerabilities.

**Exclusions.** If the calling agent states that its own exclusion rule replaces this default,
apply it. Otherwise keep every exclusion `analyze-codebase` made, do not re-judge the operations it
retained, and judge each operation you add with its Step 4 criterion. Under any rule, even for an
operation `analyze-codebase` retained, exclude one that revokes the current session or
bearer token server-side (not one that only clears a cookie), deletes the auth user, exists to
change their password or other credentials, or shuts the application down. Cite the handler for
every exclusion.

**Scan-risk.** An operation the active rule retains may still be turned against the run by a
fuzzed request — global settings that could disable login or signup, or an update of the auth
user's own profile that could change the username, password, or role. Register it and list it under **Scan-risk entrypoints** in the Output with a one-line reason
citing the handler.

### Step 5: Register and verify

Register reads and creates first, then updates, and destructive operations (delete, deactivate,
reset, purge, revoke…) last, each against a sacrificial object from Step 2. Never target
the user, session, or credential an auth object depends on, or objects other entrypoints
reference.

**Register through a file.** Per auth object, request-carried credential, or public routes: when
the auth object obtains its credential through requests (not static headers alone) and more than
10 of its operations remain, when more than 50 remain, or once a registration meets a login rate
limit or lockout, register the rest with the `compose-har` skill, loaded in full, and verify
them once each discovery completes; a shipped spec only informs their Steps 1–2. For the others,
if the repository ships a machine-readable API definition (OpenAPI/Swagger, or a template that
renders one), register their surface from it; the code inventory stays the source of truth.
Render or copy it to the run's temp directory, point its server URL at the API's mount on
`baseUrl` (OAS3 `servers`; Swagger 2 `schemes`, `host`, `basePath`), and diff its operations
with the Step 1 inventory both ways: drop from the copy what the code does not define, Step 4
excludes, or `compose-har` registers, plus scan-risk and destructive operations (register those
by hand, in this step's order); register by hand every inventory operation it lacks.
`uploadApiDefinition` the copy (base64 `content` + `filename`, or `url` if the app serves it
unchanged), then `runDiscovery` with the `fileId`, the Repeater, and the `authObjectId` guarding
that surface. Handle the results as Step 6 says, health-checking one before editing the rest;
delete any on another host. Spec examples alone are not evidence.

Register each operation with `addEntrypoint`: `projectId`; `request` with `method`, `url`,
`headers` as an object of name→string array (including the content type), and `body`;
`repeaterId` for private or local targets; and the `authObjectId` of the mechanism guarding the
route's group, none for public routes, so a scan also tests them and JavaScript anonymously.
Put a request-carried credential from `setup-auth` in the request. Do not register routes of a
gap mechanism; the Step 7 diff lists them with `setup-auth`'s quoted response. `addEntrypoint`
returns only `entrypointId`, not health.

**Health.** Call `getEntrypoint` (`projectId`, `entrypointId`) and read `response.status`,
`response.headers["content-type"]`, and `response.body`. Healthy is the handler's success path as
the code defines it, whichever apply: status, content type, redirect target, effect (a
change you can read back). A redirect, empty list, or bare 2xx alone is not proof: create what
it should show (Step 2) and check again, or count it unhealthy. Unhealthy is no `response`
object (Bright got no answer — check `testAuth`, the target, and the Repeater first), any 4xx or
5xx, or a `text/html` SPA `index.html` shell on a route that should return JSON or a file. The
top-level `status` (`new`/`changed`/`tested`/`vulnerable`) is the security status, not health.

**Evidence.** Every gap, health verdict, and runtime-based exclusion cites a request actually
sent and quotes its response. Never register an unevidenced value (an invented ID, another
mechanism's credentials) as real: obtain it or record a gap.

Check health at these points; Step 7 reconciles the rest:

- after the first registration of each kind — public, per mechanism, mutating: check one before
  registering the rest of that kind, and fix a systemic cause (auth object, Repeater, base URL,
  the content type the framework expects) first
- after each destructive registration: call `testAuth` with each saved `authObjectId`. A `curl`
  with your own token, or re-reading an entrypoint, does not test an auth object
- after every `editEntrypoint`

**Fixing.** The auth map's rejection or no response on an authenticated route goes back to
`setup-auth`; if its mechanism ends as a gap, delete those entrypoints.
Otherwise read the error in `response.body`, fix the values or path with `editEntrypoint`, and
check again — at most 3 attempts. Then keep an entrypoint whose handler answered as unhealthy
with its status and message; delete one whose request never reached the handler (404, SPA shell,
no response) with `deleteEntrypoint` and record a gap.

**Unreachable target.** If `addEntrypoint` or `editEntrypoint` fails with "Cannot access the
target" or similar, stop registering and list the failed requests. Recover in at most 3
attempts, each one restart of the Repeater (`setup-repeater` Step 3) or the app, then one `curl`
of `baseUrl` and one `listRepeaters` check for `status` `connected`. Once both succeed, retry
exactly the failed registrations; after 3 failed attempts, record them as gaps.

### Step 6: Crawl only as a fallback

Use `runDiscovery` with `crawlerUrls` only for the gaps Step 1 listed — a large surface is not a
reason. Pass `projectId`, a descriptive `name`, `crawlerUrls` seeded at the gap (not just the
`baseUrl`), `repeaters` as a single-element array for private or local targets, and the
`authObjectId` of the mechanism guarding the seeded area (none if public), one crawl per auth
object. A user-supplied HAR (uploaded as `compose-har` Step 4 says) or a synthesized OpenAPI
document (`uploadApiDefinition`), then `runDiscovery` with its `fileId`, can fill a gap the
same way.

For every discovery, poll `getDiscoveryStatus` until it completes, then read the
results with `listDiscoveryEntrypoints` (`limit: 100`, following `next`) and
`getDiscoveryEntrypoint`. Results are discovery-scoped: `editEntrypoint` and `deleteEntrypoint`
need the project entrypoint ID, from its `targetEntrypointId`. Put every result through Steps 3–4 (delete duplicates and noise), then
give the survivors Step 2 values, their route group's `authObjectId`, and Step 5 health checks.

If a discovery came back thin, check `getDiscoveryWarnings` (unreachable or unauthenticated
routes) and `getDiscoveryLogs` (the request trace) before concluding the surface is small —
usually a missing or expired auth object, shallow seeds, or an unreachable Repeater.

### Step 7: Final review

Read this target's entrypoints with `listEntrypoints` (`projectId`,
`host: ["<host[:port] of baseUrl>"]`, `limit: 100`), following every `next`. Then:

1. Diff the Step 1 inventory — operations and JavaScript — against that list, one by one: each
   item is covered by an entrypoint ID, excluded with its evidence, or missing. Register what is
   missing or record it as a gap with its evidence, and write the diff out: it is the Output's
   only source of gaps.
2. Reconcile health: `getEntrypoint` every listed entrypoint not read since its last edit
   (`listEntrypoints` has no parameters or health), and build the final table from the reads:
   ID, method, URL, `authObjectId`, the parameters in `request`, `response.status` and content
   type. Only a response on the handler's success path (Step 5) is healthy; no response, a 4xx
   or 5xx, or an empty 2xx where seeded data should match is unhealthy.
3. Confirm no two entrypoints cover one operation, no static noise remains (JavaScript kept), and
   every unhealthy entrypoint has been through Step 5 Fixing — fixed, kept as unhealthy with its
   response quoted, or deleted as a gap.

If items 1–3 changed anything, repeat the paginated `listEntrypoints` and item 2 before the
Output; an entrypoint not read since its last edit is never healthy.

### Output

Build the Output only from the last Step 7 reconciliation — never from memory, tallies, or
estimates — and claim nothing Bright's responses do not support (parameters not in `request`,
"excluded X" while X is registered). Never call the set validated, healthy, or complete while any
entrypoint is unhealthy, unread, or has no response.

Return:

- a counts line `inventory N / registered M (healthy H, unhealthy U) / excluded E / gaps G` in
  exact numbers, never `~`: M from the last paginated `listEntrypoints`, H + U = M from the
  reconciliation, E and G from the Step 7 diff. Other reported numbers must match it
- the final active set a scan reuses — every entrypoint left after Step 7, healthy or not:
  project entrypoint ID, method, URL, `authObjectId`, the values stored in `request`, and
  Bright's recorded `response.status`. A large set may go to a file in the run's temp directory,
  path printed; always list the unhealthy ones separately inline with their quoted response
- **scan-risk entrypoints**, each with its one-line reason
- excluded operations with handler evidence, and coverage gaps with evidence for each missed or
  pruned route
- duplicates merged and noise excluded, with counts
- the discovery path — whitebox, plus any crawl, spec upload, or `compose-har` file with its
  `discoveryId` and justification
