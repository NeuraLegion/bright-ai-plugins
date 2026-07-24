#!/usr/bin/env bash
set -euo pipefail

# ─── Version Bump Script ───
# VERSION is the single source of truth. This script bumps it and propagates
# the new version into every file listed in .version-bump.json atomically.
#
# Usage:
#   bash scripts/bump-version.sh --patch      # bug fixes
#   bash scripts/bump-version.sh --minor      # new skill / significant capability
#   bash scripts/bump-version.sh --major      # breaking changes
#   bash scripts/bump-version.sh --set 1.2.3  # set explicit version

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${REPO_ROOT}"

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required." >&2; exit 1; }

current="$(tr -d '[:space:]' < VERSION)"

mode="${1:---patch}"
case "$mode" in
  --patch) IFS=. read -r a b c <<< "$current"; new="${a}.${b}.$((c + 1))" ;;
  --minor) IFS=. read -r a b c <<< "$current"; new="${a}.$((b + 1)).0" ;;
  --major) IFS=. read -r a b c <<< "$current"; new="$((a + 1)).0.0" ;;
  --set)   new="${2:?--set requires a version}" ;;
  *)       echo "Usage: $0 [--patch|--minor|--major|--set X.Y.Z]" >&2; exit 1 ;;
esac

echo "Bumping ${current} → ${new}"

NEW_VERSION="$new" python3 - <<'PY'
import json, os, re, sys

new = os.environ["NEW_VERSION"]
cfg = json.load(open(".version-bump.json"))

def set_json(path, field):
    with open(path) as f:
        data = json.load(f)
    data[field] = new
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")

def set_raw(path):
    with open(path, "w") as f:
        f.write(new + "\n")

def set_yaml_frontmatter(path, field):
    text = open(path).read()
    text, n = re.subn(rf"(?m)^{field}:\s*.*$", f"{field}: {new}", text, count=1)
    if n == 0:
        sys.exit(f"ERROR: no '{field}:' frontmatter in {path}")
    open(path, "w").write(text)

def set_plugins_array(path, field):
    with open(path) as f:
        data = json.load(f)
    for p in data.get("plugins", []):
        if field in p:
            p[field] = new
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")

for entry in cfg["files"]:
    t = entry["type"]
    if t == "json":
        set_json(entry["path"], entry["field"])
    elif t == "raw":
        set_raw(entry["path"])
    elif t == "yaml-frontmatter":
        set_yaml_frontmatter(entry["path"], entry["field"])
    else:
        sys.exit(f"ERROR: unknown type {t} for {entry['path']}")
    print(f"  updated {entry['path']}")

for entry in cfg.get("marketplace_manifests", []):
    set_plugins_array(entry["path"], entry["field"])
    print(f"  updated {entry['path']} (plugins array)")
PY

echo "Done. All version-bearing files now at ${new}."
echo "Next: regenerate Cursor rules → bash scripts/generate-cursor-rules.sh"
