# bright-auth — Reach Protected Endpoints

Most real vulnerabilities live behind a login. This skill creates and validates Bright
authentication objects so discovery and scans can reach authenticated routes.

```
Identify auth pattern → Build auth object → testAuth → Attach to discovery/scan
```

**Use it when:** a scan under-covers because endpoints require login, or you're setting up scanning
for an app with authentication.

See [`skills/bright-auth/SKILL.md`](./skills/bright-auth/SKILL.md).
