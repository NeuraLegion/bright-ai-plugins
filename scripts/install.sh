#!/usr/bin/env bash
set -euo pipefail

# ─── Install Script ───
# Copies Bright agent skills into a target project for platforms that require
# manual installation (Cursor, Copilot).
#
# Usage:
#   ./scripts/install.sh --platform cursor  --target /path/to/project
#   ./scripts/install.sh --platform copilot --target /path/to/project

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS=(bright-scan bright-api bright-auth bright-ci bright-lab)

usage() {
  echo "Usage: $0 --platform <cursor|copilot> --target <project-path>" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  --platform  Platform to install for (cursor or copilot)" >&2
  echo "  --target    Path to the target project directory" >&2
  exit 1
}

platform=""
target=""

while [ $# -gt 0 ]; do
  case "$1" in
    --platform) platform="$2"; shift 2 ;;
    --target)   target="$2";   shift 2 ;;
    *)          usage ;;
  esac
done

[ -z "$platform" ] || [ -z "$target" ] && usage

if [ ! -d "$target" ]; then
  echo "ERROR: Target directory does not exist: ${target}" >&2
  exit 1
fi

case "$platform" in
  cursor)
    rules_source="${REPO_ROOT}/cursor/.cursor/rules"
    rules_dest="${target}/.cursor/rules"
    skills_dest="${target}/.cursor/skills"
    plugins_source="${REPO_ROOT}/plugins"

    if [ ! -d "$rules_source" ] || ! ls "$rules_source"/*.mdc >/dev/null 2>&1; then
      echo "ERROR: Cursor rules not found. Run 'bash scripts/generate-cursor-rules.sh' first." >&2
      exit 1
    fi

    if [ -d "$rules_dest" ] && ls "$rules_dest"/bright-*.mdc >/dev/null 2>&1; then
      echo "WARNING: Bright Cursor rules already exist in ${rules_dest}/"
      read -rp "Overwrite? [y/N] " confirm
      [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && { echo "Aborted."; exit 0; }
    fi

    # Rules
    mkdir -p "$rules_dest"
    cp "$rules_source"/*.mdc "$rules_dest/"
    count=$(ls "$rules_dest"/bright-*.mdc 2>/dev/null | wc -l | tr -d ' ')
    echo "Installed ${count} Cursor rules to ${rules_dest}/"

    # Skills (real copies — dereference the repo's internal symlinks)
    for s in "${SKILLS[@]}"; do
      mkdir -p "${skills_dest}/${s}"
      cp -RL "${plugins_source}/${s}/skills/${s}/"* "${skills_dest}/${s}/"
    done
    echo "Installed ${#SKILLS[@]} Cursor skills to ${skills_dest}/"
    ;;

  copilot)
    dest="${target}/.agents/skills"
    plugins_source="${REPO_ROOT}/plugins"

    for s in "${SKILLS[@]}"; do
      mkdir -p "${dest}/${s}"
      cp -RL "${plugins_source}/${s}/skills/${s}/"* "${dest}/${s}/"
    done
    echo "Installed ${#SKILLS[@]} Bright skills to ${dest}/"
    echo "Confirm they appear under GitHub Copilot → Configure Skills in VS Code."
    ;;

  *)
    echo "ERROR: Unknown platform '${platform}'. Use 'cursor' or 'copilot'." >&2
    exit 1
    ;;
esac
