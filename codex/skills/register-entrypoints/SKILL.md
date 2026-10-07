---
name: register-entrypoints
description: Build the endpoint inventory from the source code and register its operations in Bright with code-grounded, functional parameter values — deduplicated by operation, JavaScript kept and static noise dropped, health read from the response Bright recorded, gaps named — crawling only as a justified fallback.
---

## Register Entrypoints

Reuse the `projectId` resolved in `setup-repeater`, its Repeater, and the auth object from
`setup-auth` instead of creating new ones; Step 5 says when each is attached. Bright sends the
real request to the target on every `addEntrypoint` and `editEntrypoint`, so registration has
side effects.

### Step 1: Complete the inventory from the code

Start from the `analyze-codebase` inventory and its exclusions instead of redoing them. Complete and
verify it from the code, recording for every operation:

- the full path, including prefixes, versioning, and sub-routers mounted in middleware, and whether
  the route requires authentication
- for gRPC-gateway, the `google.api.http` mapping; request-message fields not bound to the path or
  `body` become query parameters
- every query parameter and request header this handler reads — framework accessors (e.g.
  `QueryParam(...)`, `request.args`, `req.query`, header getters) and bind/DTO tags — not a set
  copied from a neighbouring route
- the handler identity (file plus function, or RPC name), which Step 3 relies on
- if the app serves a built frontend: the JavaScript the served `index.html` references (`curl`
  the `baseUrl`), the service worker it registers, and the chunks those bundles load, or the build
  output directory (e.g. `dist/`). Record each as GET with no auth. If the repository has frontend
  source but the served `index.html` references no bundle, record JavaScript as a coverage gap:
  the frontend was not built or not served

Also list the surface the code cannot reveal — routes built at runtime, plugin route tables,
server-rendered pages that are not statically visible, parts with no source in the repository.
That list is the only input to Step 6.

### Step 2: Craft functional parameter values

An entrypoint with empty or nonsensical values fails server-side validation, never reaches the
handler, and gives a scan nothing worth mutating. Every path, query, body, and header value must
be accepted by the application and seed mutation well. Build each request from a concrete URL on
`baseUrl`, and derive every value from the code:

- **Enums and constants** — the exact member and casing (`OAUTH2`, not `oauth2`); a real key from
  an enumerated set, not `"test"`.
- **Encoded fields** — encode what the handler decodes: a JSON-decoded `value` is `"\"en\""`, not
  `"en"`.
- **Framework conventions** — e.g. gRPC-gateway Update RPCs need an `update_mask` listing the
  fields being set.
- **Types and validation** — the declared type, format hints (email, UUID, date-time, URI),
  patterns, length bounds, every required DTO field, nested object and array shapes.
- **Seeds and specs** — IDs, slugs, and foreign keys that exist in the seeded data; `example`
  values a shipped spec provides.
- **Dependent objects** — read real IDs from the running app. When a route needs an object that
  does not exist yet, create it first through the application's API with `curl` against `baseUrl`
  and the run's credentials, and create separate sacrificial objects for every destructive
  operation. If you cannot create one, record the route as a gap instead of registering a
  guaranteed 404.

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
whether an existing entrypoint already covers the operation:

- One handler, RPC, or operation is one entrypoint, whatever its parameter combinations, carrying
  the union of the parameters worth mutating.
- Two transports of one handler — a gRPC-gateway RPC path and its REST mapping — are one
  operation. Keep the one that exposes more mutable input (usually REST); register the other only
  if it reaches input the first cannot. A `q` + `method` lookup misses these pairs: match them by
  handler identity and search by the resource fragment without `method`.
- Different handlers, different method semantics on one path, or different resources stay
  distinct: `GET` and `POST` on a collection are two entrypoints, five filter variants of the
  `GET` are one.
- When an existing entrypoint covers the operation, `editEntrypoint` it with the missing
  parameters or better values instead of adding another.

### Step 4: Decide what to register

**Static noise.** Do not register CSS, images (png, jpg, gif, svg, webp, ico), fonts (woff, woff2,
ttf, otf, eot), source maps, `manifest.json` or `*.webmanifest`, `robots.txt`, `sitemap.xml`, or
other non-executable static files. Keep JavaScript — application bundles, chunks, locale bundles,
service workers — because it can carry vulnerabilities worth scanning.

**Exclusions.** If the calling agent states that its own exclusion rule replaces this default,
apply it. Otherwise keep every exclusion `analyze-codebase` made, do not re-judge the operations it
retained, and judge each operation you add with its Step 4 criterion. Under any rule, even for an
operation `analyze-codebase` retained, exclude an operation that revokes the current session or
bearer token server-side (not one that only clears a cookie), deletes the auth user, exists to
change their password or other credentials, or shuts the application down. Cite the handler for
every exclusion.

**Scan-risk.** An operation the active rule retains may still be turned against the run by a
fuzzed request — global settings whose fuzzed values could disable login or signup, or an update
of the auth user's own profile where a fuzzed field mask could change the username, password, or
role. Register it and list it under **Scan-risk entrypoints** in the Output with a one-line reason
citing the handler.

### Step 5: Register and verify

Register reads and creates first, then updates, and destructive operations (delete, deactivate,
reset, purge, vacuum, revoke…) last, each against a sacrificial object from Step 2. Never target
the user, session, or credential the auth object depends on, or objects other entrypoints
reference — deleting the only user breaks the auth object and every later registration.

Register each operation with `addEntrypoint`: `projectId`; `request` with `method`, `url`,
`headers` as an object of name→string array (including the content type), and `body`;
`repeaterId` for private or local targets; and `authObjectId` only when the route requires
authentication, so a scan also tests public routes and JavaScript anonymously. It returns only
`entrypointId`, so success says nothing about health.

**Health.** Call `getEntrypoint` (`projectId`, `entrypointId`) and read `response.status`,
`response.headers["content-type"]`, and `response.body`. Healthy is the success status and content
type the handler produces. Unhealthy is no `response` object (Bright got no answer — check
`testAuth`, the target, and the Repeater first), any 4xx or 5xx, or a `text/html` SPA
`index.html` shell on a route that should return JSON or a file. The top-level `status`
(`new`/`changed`/`tested`/`vulnerable`) is the security status, not health; if the tool also
returns `connectivity`, anything other than `ok` is unhealthy.

Check health at these points, and leave the rest to Step 7:

- after the first registration of each kind — public, authenticated, mutating: register one,
  check it, and only then register the rest of that kind; never register a batch before the first
  check. Fix a systemic cause (auth object, Repeater, base URL, the content type the framework
  expects) before continuing
- after each destructive registration: call `testAuth` with the saved `authObjectId`. A `curl`
  with your own token, or re-reading an entrypoint, does not test the auth object
- after every `editEntrypoint`

**Fixing.** A `401`/`403` or no response on an authenticated route goes back to `setup-auth`.
Otherwise read the error in `response.body`, fix the values or path with `editEntrypoint`, and
check again — at most 3 attempts. Then, if the handler answered with a 4xx, keep the entrypoint and
record it as unhealthy with its status and message. If the request never reached the handler (404,
SPA shell, no response), remove it with `deleteEntrypoint` and record it as a gap with the reason.

**Unreachable target.** If `addEntrypoint` or `editEntrypoint` fails with "Cannot access the
target" or a similar error, stop registering and keep a list of the failed requests. Recover in at
most 3 attempts; an attempt is one restart of the Repeater (`setup-repeater` Step 3) or of the app,
followed by one `curl` of `baseUrl` and one `listRepeaters` check that its `status` is
`connected`. Once both succeed, retry exactly the failed registrations. After 3 failed attempts,
stop and record them as gaps.

### Step 6: Crawl only as a fallback

Use `runDiscovery` with `crawlerUrls` only for the gaps Step 1 listed — a large surface is not a
reason. State the justification in the Output. Pass `projectId`, a descriptive `name`,
`crawlerUrls` seeded at the gap (not just the `baseUrl`), `repeaters` as a single-element array
for private or local targets, and `authObjectId`. A user-supplied HAR, or a shipped or synthesized
OpenAPI document uploaded with `uploadApiDefinition` and run through `runDiscovery` with the
returned `fileId`, can fill a gap the same way.

Poll `getDiscoveryStatus` until the discovery completes, then read the results with
`listDiscoveryEntrypoints` (`limit: 100`, following `next`) and `getDiscoveryEntrypoint`, and put
every one through Steps 3 and 4. Discovery results are discovery-scoped: `editEntrypoint` and
`deleteEntrypoint` need the project entrypoint ID, taken from the entry's target entrypoint mapping
or by finding the same method and URL with `listEntrypoints`. Delete duplicates and noise, and give
the survivors Step 2 values.

If the crawl came back thin, check `getDiscoveryWarnings` (routes it could not reach or
authenticate against) and `getDiscoveryLogs` (the request trace) before concluding the surface is
small. Usual causes: a missing or expired auth object, seeds that never link deeper, a Repeater
the target cannot be reached through.

### Step 7: Final review

Read this target's entrypoints with `listEntrypoints` (`projectId`,
`host: ["<host[:port] of baseUrl>"]`, `limit: 100`; the default page is 10), following `next` to
the last page. This read-back is the only source for the Output. Then:

1. Diff the Step 1 inventory — operations and JavaScript — against that list, one by one: each
   item is covered by an entrypoint ID, excluded with its evidence, or missing. Register what is
   missing, or record it as a gap with a reason. Write the diff out; it is the only source of the
   Output's gaps.
2. Call `getEntrypoint` for every entrypoint — `listEntrypoints` carries no parameters and no
   health — and build the final table: ID, method, URL, the parameters stored in `request`, and
   `response.status` with its content type.
3. Confirm no two entrypoints cover one operation, no static noise remains (JavaScript kept), and
   every unhealthy entrypoint has been through Step 5 Fixing — fixed, kept as unhealthy, or
   deleted as a gap.

### Output

Build the Output only from the Step 7 read-back — never from memory, running tallies, or
estimates — and claim nothing Bright's responses do not support: "all healthy" when some are not,
parameters that are not in `request`, or "excluded X" while X is registered.

Return:

- a counts line: `inventory N / registered M (healthy H, unhealthy U) / excluded E / gaps G`, with
  M from the paginated `listEntrypoints`, H and U from the `getEntrypoint` reads, E and G from the
  Step 7 diff. Any number reported elsewhere must match it
- the final active set a scan reuses — every entrypoint left after Step 7, healthy or not:
  project entrypoint IDs with method, URL, the parameter values stored in `request`, and the
  `response.status` Bright recorded; list the unhealthy ones separately with their reason
- **scan-risk entrypoints**, each with its one-line reason
- excluded operations with their handler evidence, and coverage gaps with the reason each route
  was missed or pruned
- duplicates merged and noise excluded, with counts
- the discovery path — whitebox, plus any crawl or spec upload with its `discoveryId` and
  justification
- the auth object and Repeater used
