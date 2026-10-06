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

For every operation record the method, the full path including mount prefixes, the
path/query/header/body parameters, the content type, the auth requirement, and the handler
identity (file plus function, or RPC name). Also note the surface the code cannot reveal —
routes built at runtime, plugin route tables, server-rendered pages that are not statically
visible, parts with no source in the repository. That list is the only input to Step 5.
Reuse the `projectId` resolved in `setup-repeater` for every call here.

### Step 2: Craft parameter values — top priority

This is the point of the whole run. An entrypoint whose parameters are empty or
nonsensical fails server-side validation, never reaches the handler, and gives the later
scan nothing worth mutating. Every path, query, body, and header value you emit has to be
functional: accepted by the application, semantically correct, and a good seed for mutation
and attack.

Derive each value from evidence in the code, not from a guess:

- **Enums and constants** — use a real member, not an invented string.
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
- **Real existing IDs** — read them from the running app or the seed data rather than
  inventing them.

Then apply these rules:

- Build one representative, functional value set per operation. Do not register
  combinatorial variants of optional parameters.
- Include every required parameter, plus the optional ones that widen the attack surface
  — filters, search, sort, pagination, IDs, free text, file and URL fields. Skip purely
  cosmetic ones.
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
locale bundles, and `sw.js`.

Register each kept operation with `addEntrypoint`: `projectId`, `request` with `method`,
`url`, `headers` as an object of name→string array, and `body`; plus `authObjectId` and
`repeaterId` when the target needs them. Read connectivity back with
`getEntrypoint`/`listEntrypoints`. An entrypoint that reports `Problem`, `Unauthorized`, or
a `401`/`403` is not done — fix the auth object or the parameter values, `editEntrypoint`
(or delete and re-add), and iterate until it is healthy. A `404` means the path is wrong:
fix it, or drop it and record the reason.

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
until it runs out; the default page is only 10) and confirm: no two entrypoints cover one
operation, no static noise remains (JS kept), and every entrypoint is healthy with
functional values.

### Output

Return:
- the discovery path used — whitebox, plus any fallback crawl or spec upload with its
  `discoveryId`, and the justification for any crawl
- registered entrypoint IDs with method, URL, and the populated parameter values
- duplicates merged or pruned and noise excluded, with counts and examples
- the auth object and Repeater used, if any
- coverage gaps and the reason each route was missed or pruned
