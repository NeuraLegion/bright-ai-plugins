---
name: setup-repeater
description: Select a Bright project and, for private or local targets, create or reuse a Repeater and connect it to the application under test.
---

## Setup Bright Project and Repeater

### Preconditions

Before starting a Repeater, require `BRIGHT_HOSTNAME` and `BRIGHT_TOKEN`.
Both are used by the MCP config (URL and auth header) and by the Bright CLI Repeater.
If either is missing, stop and ask the user to provide it. Expect them from the environment's
secret store (CI/cloud secrets) or the local shell environment.

A Repeater is required only for **private or local** targets. A publicly reachable target
(e.g. a public staging URL) can be scanned directly — skip to project selection and pass no
`repeaters` to the scan.

### Step 1: Select the Bright project

1. Call `listProjects`.
2. Prefer the project whose name matches the repository or application name.
3. Otherwise use the closest match or the first available project.

### Step 2: Create or reuse a Repeater (private/local targets)

1. Call `listRepeaters` for the project.
2. Reuse a healthy Repeater that is clearly scoped to this application when possible.
3. Otherwise create one with `createRepeater`, using a descriptive name such as `bright-<repo-name>`.

### Step 3: Start the Repeater

Use the same hostname and token as MCP to start the Bright CLI Repeater in the environment
that can reach the target:

```bash
npx @brightsec/cli repeater --id <REPEATER_ID> --hostname "$BRIGHT_HOSTNAME" --token "$BRIGHT_TOKEN"
```

If the CLI is not installed:

```bash
npm install -g @brightsec/cli
```

### Step 4: Verify connectivity

1. Poll `listRepeaters` until the Repeater is connected.
2. Retry up to 3 times.
3. If it never connects, capture the process output and stop.

### Output

Return:
- `projectId`
- `projectName`
- `repeaterId` (or note that the target is public and no Repeater is needed)
- whether the Repeater was reused or created for this run
