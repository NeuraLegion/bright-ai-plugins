# bright-ci — Wire It Into CI

Once a Bright scan works locally, this skill graduates it into your CI/CD pipeline. It detects your
CI provider, prompts for trigger and blocking behavior, and writes or patches the workflow file.

```
Local scan works → Detect CI provider → Plan integration → Store BRIGHT_TOKEN secret → Write pipeline → Verify
```

**Use it when:** a local Bright scan works and you want every PR or scheduled build to scan
automatically.

See [`skills/bright-ci/SKILL.md`](./skills/bright-ci/SKILL.md).
