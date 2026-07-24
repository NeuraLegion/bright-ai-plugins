# bright-scan — Scan & Fix

Embeds [Bright](https://brightsec.com) DAST scanning directly into your coding loop. Your agent
discovers entrypoints, runs a scan against your running app or API, parses the findings, and
generates prioritized fix tasks — then rescans to confirm the fix worked.

```
Code changes → Start app/API → Discover entrypoints → Run scan → Parse vulnerabilities → Fix → Rescan
```

**Use it when:** you're building features, finishing a PR, or setting up security testing for a
new project.

See [`skills/bright-scan/SKILL.md`](./skills/bright-scan/SKILL.md) for the full workflow and
[`skills/bright-scan/references/`](./skills/bright-scan/references/) for the MCP tool catalog,
CLI reference, and findings schema.
