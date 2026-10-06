---
name: discover-and-register
description: Discover the attack surface by crawl, API specification, or HAR, and register every entrypoint in Bright with code-grounded parameter values that pass validation and mutate well.
---

## Discover and Register Entrypoints

### Step 1: Choose the discovery inputs

Pick the discovery mode (or modes) from what the repository actually offers:

- **Crawl** when the application serves a reachable UI or a set of seed URLs that
  exercise the routes. Good for surfaces that are hard to enumerate from code alone.
- **API specification** when the repository ships an OpenAPI/Swagger or GraphQL
  schema, or when `analyze-codebase` produced a clean route inventory you can turn
  into one.
- **HAR** when the user handed you a recorded session, or when a quick scripted walk
  of the app produces a representative trace.

Run more than one mode when they cover different parts of the surface — a crawl for the
rendered UI and an API spec for the back-end routes it never links to. Record the
`projectId` resolved in `setup-repeater` and reuse it for every call here.

### Step 2: Crawl discovery

Launch a crawl with `runDiscovery`, passing:
- `projectId` and a descriptive `name`
- `crawlerUrls`: the seed URLs the crawler starts from (the `baseUrl` and any routes
  that are not linked from the landing page)
- `repeaters`: the active Repeater as a single-element array for private or local
  targets — omit it for a public target
- `authObjectId`: the auth object resolved earlier, so the crawl reaches
  authenticated routes instead of bouncing off the login wall

Let the crawl complete, then reconcile its output in Step 5.

### Step 3: API-specification discovery

When the repository already ships a specification file, upload it with
`uploadApiDefinition` (`projectId` plus either `url` for a hosted spec, or `content` as
base64 with a `filename`). Pass the returned `fileId` to `runDiscovery` alongside
`projectId`, `name`, the `repeaters` array for private/local targets, and
`authObjectId`.

When there is no specification, synthesize a minimal OpenAPI 3 document from the
`analyze-codebase` endpoint inventory — paths, methods, parameters, and request bodies
with the values worked out in Step 4 — and upload it with `uploadApiDefinition` as
base64 `content` with a `filename`. Then run discovery against the returned `fileId`.

### Step 4: Synthesize parameter values — top priority

This is the point of the whole run. A discovered entrypoint whose parameters are empty
or nonsensical fails server-side validation, never reaches the handler, and gives the
later scan nothing worth mutating. Every path, query, body, and header value you emit
has to be functional: accepted by the application, semantically correct, and a good
seed for mutation and attack.

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

Never register a placeholder such as `{}` or an empty string where the route logic
clearly expects richer input. A value that passes validation but pins the request to one
rigid shape is a poor seed; prefer realistic values that leave room for the scanner to
mutate the type, length, and content.

### Step 5: Register and verify

1. Call `listDiscoveryEntrypoints` for the `projectId` and `discoveryId`, and read each
   one back with `getDiscoveryEntrypoint` to see the request discovery actually built.
2. Compare that against the retained inventory from `analyze-codebase`. For any route
   discovery missed, build the request with Step 4 values and add it with `addEntrypoint`
   (`projectId`, `request` with `method`, `url`, `headers` as an object of
   name→string array, and `body`; plus `authObjectId` and `repeaterId` when the target
   needs them). Call `listEntrypoints` first and reuse a matching entrypoint instead of
   creating a duplicate.
3. Read connectivity back with `getEntrypoint`/`listEntrypoints`. An entrypoint that
   reports `Problem`, `Unauthorized`, or a `401`/`403` is not registered correctly —
   fix the auth object or the parameter values and iterate, do not keep it.

### Step 6: Debug coverage

If the crawl or spec run came back thin, inspect why before concluding the surface is
small. Read `getDiscoveryWarnings` for routes the crawler could not reach or
authenticate against, and `getDiscoveryLogs` for the request-level trace. Common causes
are a missing or expired auth object, seed URLs that never link to the deeper routes, and
a Repeater the target cannot be reached through.

### Output

Return:
- discovery mode(s) used, with the `discoveryId` for each
- registered entrypoint IDs with method, URL, and the populated parameter values
- the auth object and Repeater used, if any
- coverage gaps and the reason each route was missed or pruned
