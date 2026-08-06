---
name: analyze-codebase
description: Detect the technology stack and discover safe HTTP endpoints that can be scanned through Bright DAST.
---

## Analyze Codebase

### Step 1: Detect the technology stack

Read top-level files such as `package.json`, `go.mod`, `requirements.txt`, `Gemfile`,
`pom.xml`, `Cargo.toml`, `Dockerfile`, and `docker-compose.yml`.

Identify:
- languages
- frameworks
- databases
- startup commands
- likely ports

### Step 2: Find route definitions or API definitions

Look for:
- OpenAPI or Swagger files
- GraphQL schemas
- controller files
- route files
- framework decorators and middleware that define endpoints

Framework-oriented search patterns:

| Framework | File patterns |
|-----------|---------------|
| Express or Fastify | `src/**/*.routes.{ts,js}`, `src/**/*.controller.{ts,js}`, `routes/**/*.{ts,js}` |
| NestJS | `src/**/*.controller.ts` |
| Django | `**/urls.py` |
| Flask or FastAPI | `**/*.py` with route decorators |
| Rails | `config/routes.rb`, `app/controllers/**/*.rb` |
| Spring | `**/*Controller.java`, `**/*Resource.java` |
| Go | `**/*handler*.go`, `**/*router*.go`, `**/routes.go` |

### Step 3: Extract safe endpoints

For each endpoint, capture:
- method
- path
- body schema with realistic sample values
- query parameters with realistic sample values
- content type

### Step 4: Filter destructive endpoints

Remove endpoints that should not be fuzzed automatically:

1. All `DELETE` endpoints.
2. `PUT` or `PATCH` endpoints that mutate user identity, credentials, or profile ownership.
3. Endpoints whose request body includes `password`, `newPassword`, `currentPassword`, `oldPassword`, or `passwd`.

### Output

Return:
- stack summary
- startup options
- total endpoints discovered
- safe endpoints retained for scanning
- filtered endpoints and the reason they were excluded
