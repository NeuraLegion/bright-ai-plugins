# Bright Security

Bright Security plugin for Cursor.

## Included agents

- `bright-application-testing`: analyze the repository, start the application in the
    current execution environment, configure Bright, and run DAST scans through a Repeater.
- `bright-remediation-loop`: reproduce findings with DAST, apply minimal fixes,
  restart the application, and run the same validation scans until findings are gone.

## Included skills

- `analyze-codebase`
- `setup-repeater`
- `setup-auth`
- `register-entrypoints`
- `run-scan`
- `fix-and-validate`

## Required environment

- `BRIGHT_HOSTNAME`: Bright cluster hostname (for example `app.brightsec.com`).
- `BRIGHT_TOKEN`: Bright API token for MCP requests and the Bright CLI Repeater.
- An application target you own or are authorized to test (a local dev server, a staging/QA environment, or another authorized host). Private/local targets are reached through a Bright Repeater.

## Cloud-first prerequisites

1. Connect the repository to Cursor Cloud Agents.
2. Create a Bright API token in Bright.
3. Add `BRIGHT_HOSTNAME` and `BRIGHT_TOKEN` to Cursor Cloud Agent secrets.
4. Configure and enable the Bright MCP server for Cloud Agents.
5. Start the Bright agent in Cloud mode.

Cloud Agent MCP configuration should mirror `mcp.json`:

- Name: `brightsec`
- Transport: HTTP
- URL: `https://${env:BRIGHT_HOSTNAME}/mcp`
- Header: `Authorization: Api-Key ${env:BRIGHT_TOKEN}`

If the application requires login, add those credentials to Cloud Agent secrets too.

If your team restricts cloud egress, allowlist your `BRIGHT_HOSTNAME`.

## Desktop fallback

If you run the plugin in desktop Cursor instead of Cloud Agents, export `BRIGHT_HOSTNAME`
and `BRIGHT_TOKEN` in your shell or user environment and enable the Bright MCP server in
Cursor Settings.

For macOS or Linux:

```bash
echo 'export BRIGHT_HOSTNAME="app.brightsec.com"' >> ~/.zshrc
echo 'export BRIGHT_TOKEN="your-bright-api-token"' >> ~/.zshrc
source ~/.zshrc
```

For Windows PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("BRIGHT_HOSTNAME", "app.brightsec.com", "User")
[Environment]::SetEnvironmentVariable("BRIGHT_TOKEN", "your-bright-api-token", "User")
```

This plugin uses the same hostname and token in two places:

- `mcp.json` for Bright MCP HTTP requests
- the Bright CLI Repeater process started by the agents in the current execution environment

Do not rely on a repository `.env` file as the primary cloud setup. Use Cloud Agent secrets for cloud execution, or a shell or user environment variable for desktop execution.

## Verify and troubleshoot

- In Cloud Agents, confirm `BRIGHT_HOSTNAME` and `BRIGHT_TOKEN` exist in secrets and the Bright MCP server is enabled in the Cloud Agent MCP UI.
- In desktop Cursor, check `echo $BRIGHT_HOSTNAME` and `echo $BRIGHT_TOKEN` before opening Cursor chat tools.
- If Bright tools are missing, reload Cursor and confirm the Bright MCP server is enabled in the correct UI.
- If Bright authorization fails, replace the API token and restart Cursor.
- If only the Repeater fails, test the CLI manually with `npx @brightsec/cli repeater --id <REPEATER_ID> --hostname "$BRIGHT_HOSTNAME" --token "$BRIGHT_TOKEN"`.