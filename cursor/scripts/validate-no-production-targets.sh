#!/usr/bin/env bash
set -euo pipefail

command_input="${1:-}"

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
  exit 1
fi

exit 0