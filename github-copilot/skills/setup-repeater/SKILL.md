---
name: setup-repeater
description: Establish the Bright project for the run and, for private or local targets, create or reuse a Repeater and connect it to the application under test.
---

## Setup Bright Project and Repeater

### Preconditions

`BRIGHT_TOKEN` authenticates every Bright operation. `BRIGHT_HOSTNAME` selects the Bright
cluster and is required to start the Repeater. Expect both values from the environment's secret
store (CI/cloud secrets) or the local shell environment.

Verify them before the first Bright call, so a missing value surfaces as a clear message instead
of an opaque connection or authentication failure:

```bash
test -n "$BRIGHT_TOKEN" && echo "BRIGHT_TOKEN: set" || echo "BRIGHT_TOKEN: MISSING"
test -n "$BRIGHT_HOSTNAME" && echo "BRIGHT_HOSTNAME: $BRIGHT_HOSTNAME" || echo "BRIGHT_HOSTNAME: MISSING"
```

If `BRIGHT_TOKEN` reports `MISSING`, stop. Tell the user to export it in the shell they launch
the tool from and restart the session, because the MCP server reads it at startup:

```bash
export BRIGHT_TOKEN="your-bright-api-token"
export BRIGHT_HOSTNAME="app.brightsec.com"
```

Never ask the user to paste the token into the conversation, and never work around a missing one.

If only `BRIGHT_HOSTNAME` is missing, a public target can still be scanned directly — resolve the
project in Step 1 and skip the Repeater. Ask for the hostname before Step 3 if a Repeater turns
out to be necessary.

How the MCP server itself gets these differs by tool — some read them from the environment on
each call, others had them fixed when the server was registered. Do not assume the MCP server
points at `BRIGHT_HOSTNAME`; if Bright calls fail on authentication or reach the wrong cluster,
report that the MCP server needs re-registering instead of retrying.

A Repeater is required only for **private or local** targets. A publicly reachable target
(e.g. a public staging URL) can be scanned directly: still resolve the project in Step 1, then
skip Steps 2–4 and pass no `repeaters` to the scan.

### Step 1: Resolve the Bright project

Every Bright object created in this run — the Repeater, the auth object, the entrypoints, and
the scans — is scoped to one project. Resolve it once, before creating anything.

1. If the user gave a project (id or name), use it and continue to Step 2.
2. Otherwise call `listProjects` and ask the user which one to use.

Do not choose on the user's behalf: not by repository-name similarity, and not by taking the
first result. A wrong guess writes scan data into someone else's project, and picking again
later leaves the Repeater and the scan in different projects.

Record the resolved `projectId` and pass that same value to every later Bright call in this
run. Never resolve it a second time.

### Step 2: Create or reuse a Repeater (private/local targets)

1. Call `listRepeaters` for the project.
2. Reuse a healthy Repeater that is clearly scoped to this application when possible.
3. Otherwise create one with `createRepeater`, using a descriptive name such as `bright-<repo-name>`.

### Step 3: Start the Repeater

The Repeater has to run against the same Bright cluster as the MCP server. If it does not,
nothing errors: the Repeater registers on one cluster while the scan runs on another, and the
scan simply never finds it. Passing the configured hostname below keeps both sides on the same
cluster — do not substitute a different one.

The Repeater runs here, on the machine this agent is running on. It is what gives Bright a route
to a target that is not reachable from the internet, so the target has to be reachable from
here — over localhost, the local network, a VPN, a tunnel, or a port-forward the user already
has in place. Setting that up is the user's side of it; confirm the target answers from this
machine before starting the Repeater, and stop and say so if it does not.

Start the Bright CLI Repeater:

```bash
npx @brightsec/cli repeater --id <REPEATER_ID> --hostname "$BRIGHT_HOSTNAME" --token "$BRIGHT_TOKEN"
```

If the CLI is not installed:

```bash
npm install -g @brightsec/cli
```

### Step 4: Verify connectivity

1. Poll `listRepeaters` until the Repeater is connected. This call goes through the MCP server,
   so it is also the check that both sides agree on the cluster: a Repeater whose process is
   running but never appears here was started against a different one.
2. Retry up to 3 times.
3. If it never connects, capture the process output and stop.

### Output

Return:
- `projectId`
- `projectName`
- `repeaterId` (or note that the target is public and no Repeater is needed)
- whether the Repeater was reused or created for this run
