# Releasing

`VERSION` is the single source of truth. Every platform manifest must match it.

## PR workflow

Before opening a PR, bump the version and include it in the commit:

```bash
bash scripts/bump-version.sh --patch   # bug fixes
bash scripts/bump-version.sh --minor   # new skill / significant capability
bash scripts/bump-version.sh --major   # breaking changes
```

Then regenerate Cursor rules (they are generated output and must stay in sync):

```bash
bash scripts/generate-cursor-rules.sh
git add cursor/
```

## Validate before release

```bash
# 1. Versions consistent everywhere
grep -R --line-number "\"version\"" plugins .claude-plugin .codex-plugin plugin.json gemini-extension.json

# 2. Cursor rules regenerate with no diff (idempotent)
bash scripts/generate-cursor-rules.sh && git diff --exit-code cursor/

# 3. All JSON parses
find . -name '*.json' -not -path './.git/*' -exec python3 -c "import json,sys;json.load(open(sys.argv[1]))" {} \;

# 4. Symlinks resolve
for d in skills .opencode/skills .cursor/skills; do
  for l in "$d"/*; do test -e "$l" || echo "BROKEN: $l"; done
done
```

## Tag & publish

```bash
git tag -a "v$(cat VERSION)" -m "Release v$(cat VERSION)"
git push origin "v$(cat VERSION)"
```

Create a GitHub Release from the tag. For Claude/Codex, the marketplace is served straight from the
repo (`/plugin marketplace add NeuraLegion/bright-ai-plugins`), so a merged, tagged `main` is the
release.
