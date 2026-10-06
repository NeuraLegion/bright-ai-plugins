---
name: discover-and-register
description: Discover the attack surface whitebox from the source code and register every entrypoint in Bright directly, with code-grounded parameter values that pass validation and mutate well; crawl only as a justified fallback, with semantic deduplication and no static-asset noise.
---

## Discover and Register Entrypoints

### Step 1: Build the inventory from the code (primary path)

Whitebox discovery is the default and the main deliverable. You have the source, so build
the full inventory from it instead of waiting for a crawler to stumble onto routes. Start
from the `analyze-codebase` inventory and complete it by reading:

- routers and route tables, controllers, and handlers
- middleware that shapes the surface — auth, path prefixes, versioning, mounted
  sub-routers
- proto/gRPC-gateway annotations (`google.api.http` gives the REST path and method)
- DTOs, validators, and request schemas
- OpenAPI/Swagger annotations or a shipped specification
- the built frontend, if the app serves one: list its JavaScript from the script tags and
  service-worker registration of the served `index.html` (`curl` the `baseUrl`) and/or the
  build output directory (e.g. `dist/`, an embedded-frontend package). Record each bundle
  as GET with no auth

For every operation record the method, the full path including mount prefixes, the
path/query/header/body parameters, the content type, the auth requirement, and the handler
identity (file plus function, or RPC name). Query parameters must be the complete list of
everything the handler reads: framework accessors (e.g. `QueryParam(...)`,
`request.args`, `req.query`), bind/struct/DTO tags, and, for gRPC-gateway, request-message
fields not bound to the path or `body`, which become query parameters on GET.

Also note the surface the code cannot reveal — routes built at runtime, plugin route
tables, server-rendered pages that are not statically visible, parts with no source in the
repository. That list is the only input to Step 5.
Reuse the `projectId` resolved in `setup-repeater` for every call here.

### Step 2: Craft parameter values — top priority

This is the point of the whole run. An entrypoint whose parameters are empty or
nonsensical fails server-side validation, never reaches the handler, and gives the later
scan nothing worth mutating. Every path, query, body, and header value you emit has to be
functional: accepted by the application, semantically correct, and a good seed for mutation
and attack.

Derive each value from evidence in the code, not from a guess:

- **Enums and constants** — use the exact member, with exact casing, from the enum or
  const definition (e.g. `OAUTH2`, not `oauth2`). When a field names a setting or key from
  an enumerated set, use a real one (e.g. a system-setting `name` from its enum, not
  `"test"`).
- **Encoded fields** — when the handler decodes a string field as JSON (or base64, etc.),
  encode the value that way (e.g. a setting `value` of `"\"en\""`, not `"en"`).
- **Framework conventions** — e.g. gRPC-gateway Update RPCs that take a FieldMask need an
  `update_mask` listing the fields being set, or they are rejected.
- **Types and formats** — match the declared type, and honour format hints such as
  email, UUID, date-time, or URI.
- **Regex and validation rules** — satisfy the pattern, length bounds, and required
  flags the handler or DTO enforces.
- **DTO/schema constraints** — populate every required field; respect nested object and
  array shapes.
- **Database seeds and fixtures** — prefer IDs, slugs, and foreign keys that actually
  exist in the seeded data, so lookups resolve instead of 404ing.
- **Specification examples** — reuse the `example`/`examples` values a shipped spec
  already provides.
- **Dependent objects** — read real IDs from the running app or the seed data rather than
  inventing them. When a route needs an object that does not exist yet (e.g. a child
  resource, a referenced identity provider, a relation between two records), create it
  first through the application's API with `curl` against `baseUrl` and the run's
  credentials, and use its real ID. If you cannot create it, record the route as a gap
  instead of registering a guaranteed 404.

Then apply these rules:

- Build one representative, functional value set per operation. Do not register
  combinatorial variants of optional parameters.
- Include every required parameter, plus the optional ones that widen the attack surface
  — filters, search, sort, pagination, IDs, free text, file and URL fields. Skip purely
  cosmetic ones. Every attack-relevant query parameter from Step 1 goes into the URL; a
  GET entrypoint without query parameters when its handler reads them (e.g. a list
  endpoint with filter and pagination parameters) is a defect.
- Values must pass server-side validation, reach the handler, and seed mutation well:
  realistic rather than rigid — a non-trivial string, a real numeric ID, a valid email.
- Never register `{}`, `""`, `string`, `0`, or `null` placeholders where the route logic
  clearly expects richer input.
- Bright parameter templates such as `{{entrypoint.params.query_limit}}` in a URL are the
  platform's own templating and are fine.

### Step 3: Deduplicate semantically before every registration

Deduplication is your judgement about operations, not a regex or a method-plus-path rule.
Before each `addEntrypoint`, call `listEntrypoints` with the `projectId`, narrowed with `q`
(a path fragment) and `method`, and decide whether an existing entrypoint already covers
the same operation:

- Same handler, RPC, or operation means the same entrypoint, even when the query or body
  parameter set or the values differ.
- Parameter combinations of one handler collapse into one entrypoint whose request carries
  the union of the parameters worth mutating.
- Two transports of one handler — a gRPC-gateway RPC path and its REST mapping — are one
  operation. Keep the one that exposes more mutable input (usually REST, with path and
  query parameters); register the other only if it reaches input the first cannot. A
  `q` + `method` lookup cannot find these pairs because both the method and the path
  differ: match them by the handler identity recorded in Step 1, and search by the
  resource fragment (for example `users`) without a `method` filter.
- Distinct operations stay distinct: a different handler, different method semantics on the
  same path, or a different resource.
- When an existing entrypoint covers the operation, reuse it — `editEntrypoint` to add the
  missing parameters or better values — instead of creating a new one.

Examples from a real run against Memos (Go, Echo, gRPC-gateway), which produced 75
entrypoints:

- `GET /api/v1/memo` registered five times — `?offset&limit`, `?rowStatus`,
  `?rowStatus&limit`, `?creatorUsername&rowStatus&limit`, and bare. That is ONE entrypoint
  carrying `creatorUsername`, `rowStatus`, `offset`, and `limit`.
- `POST /api/v1/memo` registered twice, once manually and once by the crawl. That is one.
- `POST /memos.api.v2.UserService/GetUser` next to `GET /api/v2/users/{username}`,
  `.../ListResources` next to `/api/v2/resources`, and `.../ListUserAccessTokens` next to
  `/api/v2/users/{username}/access_tokens` share a handler. Keep one per operation, unless
  the second adds attack surface the first does not.
- `GET /api/v1/memo` and `POST /api/v1/memo` are distinct operations. Keep both.

### Step 4: Register and verify

Exclude static noise first. Do not register:

- CSS
- images — png, jpg, gif, svg, webp, ico and favicons
- fonts — woff, woff2, ttf, otf, eot
- source maps (`.map`)
- `manifest.json` and `*.webmanifest`, `robots.txt`, `sitemap.xml`, `humans.txt`, and
  other non-executable static files

Keep JavaScript — `.js`/`.mjs` application bundles, locale and chunk bundles, and service
workers such as `sw.js` — because JS can carry vulnerabilities worth scanning. In the Memos
run that means dropping `/assets/*.css` and `manifest.json` and keeping `/assets/*.js`, the
locale bundles, and `sw.js`. Without a crawl, take them from Step 1's served-frontend list
and register each bundle as GET without `authObjectId`.

Bright sends the real request to the target on every `addEntrypoint` and `editEntrypoint`,
so registration has side effects. Register reads and creates first, then updates, and
destructive operations (delete, deactivate, reset, purge, vacuum, revoke…) last. Point
destructive operations only at sacrificial objects created for that purpose (Step 2's
dependent-objects rule). Never target the user, session, or credential the auth object
depends on, or objects other entrypoints reference — in one run, deleting the only user
broke the auth object and every later registration. This complements, not replaces, the
agent's rule to exclude effects that cannot be undone.

Register each kept operation with `addEntrypoint`: `projectId`, `request` with `method`,
`url`, `headers` as an object of name→string array, and `body`; plus `authObjectId` and
`repeaterId` when the target needs them. It returns only `entrypointId`, so success says
nothing about health.

Check health after every `addEntrypoint` and `editEntrypoint` — this is mandatory. Call
`getEntrypoint` (`projectId`, `entrypointId`) and read `response.status`,
`response.headers["content-type"]`, and `response.body`. Healthy means the success status
the handler returns, with the content type it produces. Unhealthy means any of:

- no `response` object — Bright got no answer; check the auth object with `testAuth` and
  the target/Repeater
- any 4xx or 5xx
- a `text/html` SPA `index.html` shell on a route that should return JSON or a file

The top-level `status` (`new`/`changed`/`tested`/`vulnerable`) is the security status, not
health. If the tool also returns `connectivity`, anything other than `ok` is unhealthy.

A `401`/`403` or no response on an authenticated route goes back to auth setup first.
Otherwise, when unhealthy, read the error in `response.body`, fix the values or the path
with `editEntrypoint`, and check again — at most 3 attempts. Then, if the handler answered
with a 4xx, keep the entrypoint and record it as unhealthy with its status and message. If
the request never reached the handler (404, SPA shell, no response), remove it with
`deleteEntrypoint` and record it as a gap with the reason.

If `addEntrypoint` or `editEntrypoint` fails with "Cannot access the target" (or a similar
unreachable-target error), stop registering and keep a list of the failed requests. `curl`
the `baseUrl` and check `listRepeaters` until the Repeater's `status` is `connected`,
restarting the Repeater (`setup-repeater` Step 3) and/or the app as needed. Then retry
exactly the failed registrations before continuing.

Optionally, the code-derived inventory can also be synthesized into an OpenAPI 3 document
and uploaded with `uploadApiDefinition` (`projectId` plus `url`, or base64 `content` with a
`filename`), then run through `runDiscovery` with the returned `fileId`, the `repeaters`
array for private/local targets, and `authObjectId`. Its results pass Step 3 and the noise
filter like anything else; direct registration remains the deliverable.

### Step 5: Crawl only as a fallback

Use `runDiscovery` with `crawlerUrls` ONLY when the Step 1 inventory is clearly incomplete:
routes generated at runtime, plugin or route tables resolved at runtime, server-rendered
pages not visible statically, or no source for part of the surface. State the justification
explicitly in the run and in the Output. Never crawl just in case.

Pass `projectId`, a descriptive `name`, `crawlerUrls` (seeds for the gap, not just the
`baseUrl`), `repeaters` as a single-element array for private or local targets, and
`authObjectId`. A user-supplied HAR may fill a gap the same way.

When it completes, read the results with `listDiscoveryEntrypoints` (page through all of
them with `limit: 100` and `next`) and `getDiscoveryEntrypoint`, and run every one through
the noise filter and Step 3. Discovery results are discovery-scoped; `deleteEntrypoint` and
`editEntrypoint` need the project entrypoint ID they map to. Take it from the discovery
entry's target entrypoint mapping, or find the same method and URL with `listEntrypoints`.
Remove semantic duplicates and noise with `deleteEntrypoint`, and give the survivors Step 2
values with `editEntrypoint`.

If the crawl came back thin, inspect why before concluding the surface is small. Read
`getDiscoveryWarnings` for routes the crawler could not reach or authenticate against, and
`getDiscoveryLogs` for the request-level trace. Common causes are a missing or expired auth
object, seed URLs that never link to the deeper routes, and a Repeater the target cannot be
reached through.

### Step 6: Final review

Read every entrypoint in the project with `listEntrypoints` (`limit: 100`, following `next`
until it runs out; the default page is only 10). Then:

1. Diff the Step 1 inventory (operations and JS) against that list. Register anything
   missing, or record it as a gap with a reason.
2. Call `getEntrypoint` for every entrypoint — `listEntrypoints` carries no parameters and
   no health. From those results build the final table: ID, method, URL, the parameters
   actually stored in `request` (URL query, body, headers), and `response.status` with its
   content type.
3. Confirm no two entrypoints cover one operation, no static noise remains (JS kept), and
   every entrypoint is healthy with functional values, or is recorded as unhealthy.

### Output

Build the Output only from the Step 6 `listEntrypoints` and `getEntrypoint` results. Do not
claim anything Bright's responses do not support — "all healthy" when some are not,
parameters that are not in `request`, or "excluded X" while X is registered.

Return:
- the discovery path used — whitebox, plus any fallback crawl or spec upload with its
  `discoveryId`, and the justification for any crawl
- registered entrypoint IDs with method, URL, the parameter values stored in `request`,
  and the `response.status` Bright recorded; list unhealthy entrypoints separately
- duplicates merged or pruned and noise excluded, with counts and examples
- the auth object and Repeater used, if any
- coverage gaps and the reason each route was missed or pruned
