# bright-lab — Seed a Vulnerable Target

Generates intentionally vulnerable, ultra-minimalist applications to serve as isolated DAST test
targets ("labs") for validating Bright scans and demos.

```
Describe app → Plan minimal tree → Generate vulnerable code + UI → Dockerize → Document vulns
```

**Use it when:** you need a controlled target to exercise Bright, reproduce a class of vulnerability,
or build a demo. **Never** deploy these apps to a public or shared environment.

See [`skills/bright-lab/SKILL.md`](./skills/bright-lab/SKILL.md).
