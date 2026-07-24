# Reporting recipes

Pre-built compositions of Bright MCP read tools. All are read-only.

## Org security posture summary

1. `listProjects` → all project IDs.
2. For each project: `listVulnerabilities`.
3. Aggregate counts by severity across projects.
4. Present: total untriaged, breakdown by severity, top 3 projects by critical/high count.

## Project deep dive

1. `listScans` (project) → most recent scan ID.
2. `listScanVulnerabilities` (scan) → findings list.
3. `getScanVulnerability` for each critical/high → evidence + reproduction.
4. `getScanEntrypoint` when you need the exact request/response.
5. Present: table of METHOD + path + severity + type, criticals first.

## Stale projects

1. `listProjects`.
2. For each: `listScans` and read the latest scan timestamp.
3. Flag any project with no scan in the last 30 days.

## Scan diff (what changed since last scan)

1. `listScans` (project) → last two scan IDs.
2. `listScanVulnerabilities` for both.
3. Diff by (type, entrypoint, parameter): report **new**, **resolved**, and **still open**.

## Coverage / connectivity check

1. `listScanEntrypoints` (scan) → observed entrypoints, statuses, connectivity.
2. `getScanWarnings` / `getScanLogs` → diagnose gaps (unreachable target, auth wall, rate limiting).
3. Recommend a remedy: wire an OpenAPI spec, configure auth (`bright-auth`), or add a repeater.
