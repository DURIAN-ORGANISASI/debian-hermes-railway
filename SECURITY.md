# Security Policy

## Reporting a vulnerability

Please avoid posting exploitable details, real credentials, or sensitive deployment information in a public issue. Use GitHub's private vulnerability reporting feature for this repository if available. Otherwise, contact the maintainers through a private channel available to you.

Include affected components, impact, reproduction steps, and sanitized logs. Never include terminal passwords, Telegram/Discord bot tokens, provider API keys, Railway access tokens, or live private domains.

## Operational guidance

- Set a unique, randomly generated `TERMINAL_PASSWORD` of at least 16 characters; 24 characters or longer is recommended.
- Keep model API keys and messaging-bot tokens in Railway Variables or the Hermes setup wizard; never commit them.
- The browser terminal, ttyd, and Hermes Gateway run as non-root UID 10001 inside the application container. The entrypoint uses root only during startup to migrate existing Volume ownership, then drops privileges.
- Authorize only the intended numeric user IDs for private bots; avoid unrestricted access on a public bot.
- Attach the Railway Volume at `/opt/data` before the initial Hermes setup.
- On the first startup after the non-root update, existing `/opt/data` contents are recursively reassigned to UID/GID 10001. This preserves files but can take longer for large Volumes; do not delete or format the Volume during migration.
- Hermes Agent is pinned to v0.23.1 in the Dockerfile; version updates must change both the version and commit pin.
- Rotate or revoke any token immediately if it is exposed.
- The container supervisor manages one Gateway per container and performs graceful child-process shutdown on SIGTERM/SIGINT.
- A Volume provides persistence, not a backup, authorization control, or full-VPS isolation.
