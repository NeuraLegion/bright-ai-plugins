---
name: bright-ci
version: 0.1.0
description: >
  Wire Bright DAST into a CI/CD pipeline config file. Use when the user wants
  to "set up Bright in CI", "add Bright to my pipeline", "scan in CI", or
  "configure GitHub Actions / GitLab / Jenkins / CircleCI for Bright". Provider-
  agnostic: detects the CI system from repo files, edits the pipeline file in
  place to add a Bright CLI scan job, prompts for BRIGHT_TOKEN storage (CI-native
  secrets store), and wires commit/branch traceability. Defers local-scan
  concerns (auth, findings, triage) to bright-scan. Do NOT trigger for docs-only
  changes, informational questions about CI, or running a local scan (that is
  bright-scan) — this skill only edits CI pipeline config.
---

# Bright CI Skill

Graduates a working local Bright scan into the pipeline. This skill edits CI config only; it defers
all scan configuration and findings work to `bright-scan`.

## Prerequisites

- A Bright scan that works locally (project ID + repeater known, target reachable).
- Repo write access to the CI config file.

## Workflow

```
Detect provider → Plan (trigger + blocking) → Store BRIGHT_TOKEN → Write/patch pipeline → Verify
```

1. **Detect the CI provider** from repo files:

   | File | Provider |
   |------|----------|
   | `.github/workflows/*.yml` | GitHub Actions |
   | `.gitlab-ci.yml` | GitLab CI |
   | `Jenkinsfile` | Jenkins |
   | `.circleci/config.yml` | CircleCI |
   | `azure-pipelines.yml` | Azure Pipelines |
   | `.travis.yml` | Travis CI |
   | `bitbucket-pipelines.yml` | Bitbucket |

2. **Plan integration.** Ask: trigger (on PR, on push, scheduled baseline?) and blocking behavior
   (fail the build on high/critical, or warn-only?).

3. **Store the secret.** `BRIGHT_TOKEN` goes in the CI-native secret store — never committed.
   Also store `BRIGHT_PROJECT_ID` / repeater ID as needed. Confirm the secret exists before writing
   the job.

4. **Write/patch the pipeline.** Add a job that installs the Bright CLI, activates a repeater if the
   target is private, starts the app, runs the scan, and gates on the result. See the GitHub Actions
   shape below; adapt per provider.

5. **Verify.** Lint/validate the config and dry-run if the provider supports it. Report what was
   added and how to test it.

## GitHub Actions example

```yaml
name: Bright DAST
on:
  pull_request:
  workflow_dispatch:

jobs:
  bright-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm install -g @brightsec/cli
      # Start your app here (docker compose up -d, npm start &, …) and wait for health.
      - name: Run Bright scan
        env:
          BRIGHT_TOKEN: ${{ secrets.BRIGHT_TOKEN }}
          BRIGHT_PROJECT_ID: ${{ secrets.BRIGHT_PROJECT_ID }}
        run: |
          bright-cli scan:run \
            --token "$BRIGHT_TOKEN" \
            --project "$BRIGHT_PROJECT_ID" \
            --name "CI scan ${{ github.sha }}" \
            --crawler "http://localhost:3000" \
            --smart
```

Provider guides: https://docs.brightsec.com/docs/integrate-bright-with-your-cicd-pipeline
(GitHub Actions, GitLab, Jenkins, CircleCI, Azure Pipelines, Travis, TeamCity, JFrog).

## Guardrails

- `BRIGHT_TOKEN` is always a CI secret referenced by name — never inline it.
- Private/preview targets need a repeater; activate it in the job before scanning.
- Don't retry a build that failed on the security gate — that defeats the gate.
