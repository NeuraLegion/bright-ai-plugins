---
name: setup-repeater
description: Select a Bright project, create or reuse a Repeater, and connect it to the application target in the current execution environment.
---

## Setup Bright Project and Repeater

### Preconditions

Before starting the Repeater, require `BRIGHT_HOSTNAME` and `BRIGHT_TOKEN`.
Both are used by `mcp.json` (MCP URL and auth header) and by the Bright CLI Repeater.
If either is missing, stop and ask the user to provide it.

When running in Cursor Cloud Agents, expect both variables to come from Cloud Agent
secrets. When running in desktop Cursor, expect them from the user's shell or system
environment.

### Step 1: Select the Bright project

1. Call `listProjects`.
2. Prefer the project whose name matches the repository or application name.
3. Otherwise use the closest match or the first available project.

### Step 2: Create or reuse a Repeater

1. Call `listRepeaters` for the project.
2. Reuse a healthy Repeater that is clearly scoped to this repository when possible.
3. Otherwise create a new one with a descriptive name such as `cursor-bright-<repo-name>`.

### Step 3: Start the Repeater in the current execution environment

Use the same hostname and token as MCP to start the Bright CLI Repeater:

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
- `repeaterId`
- whether the Repeater was reused or created for this run