#!/usr/bin/env bash
set -euo pipefail

# Claude Code PreToolUse hook (matcher: Bash).
# Claude passes the tool call as JSON on stdin: {"tool_input":{"command":"..."}}.
# We extract the shell command and block any Bright scan/HTTP call that targets
# something other than localhost or *.brightsec.com. Exit code 2 blocks the call.

payload="$(cat)"

command_input="$(printf '%s' "$payload" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("tool_input",{}).get("command",""))
except Exception:
    print("")' 2>/dev/null || true)"

if [[ -z "$command_input" ]]; then
  exit 0
fi

if echo "$command_input" | grep -qiE '(brightsec|runScan|runDiscovery|curl|wget|https?://)'; then
  if echo "$command_input" | grep -qiE '(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])'; then
    exit 0
  fi

  if ! echo "$command_input" | grep -qiE 'https?://'; then
    exit 0
  fi

  if echo "$command_input" | grep -qiE 'https?://[^/]*brightsec\.com'; then
    exit 0
  fi

  echo "BLOCKED: only localhost application targets are allowed for Bright scans." >&2
  exit 2
fi

exit 0
