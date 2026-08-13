#!/usr/bin/env python3
"""Check that the shared skills and agents stay in sync across the tool packages.

Every tool package ships its own copy of the same six step skills and two
orchestration agents. The frontmatter is allowed to differ, because each tool
wires things up its own way: Copilot's agents carry an `mcp-servers` block,
Codex and Antigravity carry the agents as skills and drop `argument-hint`, and
so on. Everything below the frontmatter is the actual instruction set, and it
must be identical everywhere -- otherwise a change lands in one tool and one
tool only, and the packages quietly start behaving differently.

So the rule enforced here is:

  * the body (everything after the frontmatter) must match the canonical copy
    byte for byte
  * the frontmatter `name` and `description` must match the canonical copy
  * any other frontmatter key is tool-specific wiring and is left alone

`claude-code` is the canonical copy. Run with --fix to rewrite every variant's
body from it, keeping each variant's own frontmatter.
"""

from __future__ import annotations

import argparse
import difflib
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

PACKAGES = ["antigravity", "claude-code", "codex", "cursor", "github-copilot"]

SHARED_SKILLS = [
    "analyze-codebase",
    "fix-and-validate",
    "register-entrypoints",
    "run-scan",
    "setup-auth",
    "setup-repeater",
]

AGENTS = ["bright-application-testing", "bright-remediation-loop"]

# Where each agent lives per tool. Codex and Antigravity have no agent concept,
# so they ship the orchestration prompts as skills instead.
AGENT_VARIANTS = [
    "cursor/agents/{agent}.md",
    "antigravity/skills/{agent}/SKILL.md",
    "codex/skills/{agent}/SKILL.md",
    "github-copilot/agents/{agent}.agent.md",
    "github-copilot/.github/agents/{agent}.md",
]


def split_frontmatter(path: Path) -> tuple[str, str]:
    """Return (frontmatter, body). Frontmatter keeps its delimiters."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit(f"{path}: expected YAML frontmatter starting with ---")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit(f"{path}: frontmatter is not terminated by ---")
    return text[: end + 5], text[end + 5 :]


def frontmatter_field(frontmatter: str, key: str) -> str | None:
    """Read a single-line top-level frontmatter value."""
    for line in frontmatter.splitlines():
        if line.startswith(f"{key}:"):
            return line[len(key) + 1 :].strip()
    return None


def groups() -> list[tuple[str, Path, list[Path]]]:
    """Every (label, canonical, variants) group the check covers."""
    out = []
    for skill in SHARED_SKILLS:
        canonical = REPO / "claude-code" / "skills" / skill / "SKILL.md"
        variants = [
            REPO / pkg / "skills" / skill / "SKILL.md"
            for pkg in PACKAGES
            if pkg != "claude-code"
        ]
        out.append((f"skill {skill}", canonical, variants))
    for agent in AGENTS:
        canonical = REPO / "claude-code" / "agents" / f"{agent}.md"
        variants = [REPO / v.format(agent=agent) for v in AGENT_VARIANTS]
        out.append((f"agent {agent}", canonical, variants))
    return out


def check_orphans(covered: set[Path]) -> list[str]:
    """Flag component files the check does not know about.

    Without this, adding a sixth tool package -- or a seventh skill -- would
    pass CI while being excluded from the very check meant to cover it.
    """
    problems = []
    found: set[Path] = set()
    for pkg_dir in sorted(REPO.glob("*/skills/*/SKILL.md")):
        found.add(pkg_dir)
    for pattern in ("*/agents/*.md", "*/.github/agents/*.md"):
        found.update(REPO.glob(pattern))
    for path in sorted(found - covered):
        problems.append(
            f"{path.relative_to(REPO)}: not covered by the sync check -- "
            f"add it to {Path(__file__).name}"
        )
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--fix",
        action="store_true",
        help="rewrite each variant's body from the canonical copy",
    )
    args = parser.parse_args()

    problems: list[str] = []
    fixed: list[str] = []
    covered: set[Path] = set()

    for label, canonical, variants in groups():
        if not canonical.exists():
            problems.append(f"{label}: canonical copy missing at {canonical.relative_to(REPO)}")
            continue
        covered.add(canonical)
        canon_fm, canon_body = split_frontmatter(canonical)

        for variant in variants:
            covered.add(variant)
            rel = variant.relative_to(REPO)
            if not variant.exists():
                problems.append(f"{label}: missing variant {rel}")
                continue

            var_fm, var_body = split_frontmatter(variant)

            for key in ("name", "description"):
                want = frontmatter_field(canon_fm, key)
                got = frontmatter_field(var_fm, key)
                if want != got:
                    if args.fix:
                        var_fm = "\n".join(
                            f"{key}: {want}" if line.startswith(f"{key}:") else line
                            for line in var_fm.splitlines()
                        ) + "\n"
                        fixed.append(f"{rel}: frontmatter {key}")
                    else:
                        problems.append(
                            f"{rel}: frontmatter `{key}` differs from "
                            f"{canonical.relative_to(REPO)}\n"
                            f"      canonical: {want}\n"
                            f"      variant:   {got}"
                        )

            if var_body != canon_body:
                if args.fix:
                    variant.write_text(var_fm + canon_body, encoding="utf-8")
                    fixed.append(f"{rel}: body")
                else:
                    diff = difflib.unified_diff(
                        canon_body.splitlines(keepends=True),
                        var_body.splitlines(keepends=True),
                        fromfile=str(canonical.relative_to(REPO)),
                        tofile=str(rel),
                    )
                    problems.append(f"{rel}: body differs\n" + "".join(diff).rstrip())
            elif args.fix:
                variant.write_text(var_fm + canon_body, encoding="utf-8")

    problems.extend(check_orphans(covered))

    if args.fix:
        if fixed:
            print("Synced from claude-code:")
            for item in fixed:
                print(f"  {item}")
        else:
            print("Already in sync; nothing to write.")
        # Orphans cannot be repaired automatically.
        leftovers = [p for p in problems if "not covered by the sync check" in p]
        for item in leftovers:
            print(f"\n{item}")
        return 1 if leftovers else 0

    if problems:
        print("Packages are out of sync.\n")
        for item in problems:
            print(f"{item}\n")
        print(
            "The tool packages ship the same instructions; a change to one has to reach\n"
            "all of them. Run `python3 scripts/check_package_sync.py --fix` to propagate\n"
            "the canonical claude-code copy, then review the result."
        )
        return 1

    covered_count = len(covered)
    print(f"All {covered_count} skill and agent files are in sync across {len(PACKAGES)} packages.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
