# Security Policy

## Reporting a vulnerability

Please avoid posting exploitable details, real credentials, or sensitive deployment information in a public issue. Use GitHub's private vulnerability reporting feature for this repository if available. Otherwise, contact the maintainers through a private channel available to you.

Include affected components, impact, reproduction steps, and sanitized logs. Never include terminal passwords, Telegram/Discord bot tokens, provider API keys, Railway access tokens, or live private domains.

## Operational guidance

- Set a unique, randomly generated `TERMINAL_PASSWORD` of at least 16 characters; 24 characters or longer is recommended.
- Keep model API keys and messaging-bot tokens in Railway Variables or the Hermes setup wizard; never commit them.
- Anyone who can authenticate to the browser terminal gets root privileges inside the application container.
- Authorize only the intended numeric user IDs for private bots; avoid unrestricted access on a public bot.
- Attach the Railway Volume at `/opt/data` before the initial Hermes setup.
- Rotate or revoke any token immediately if it is exposed.
- A Volume provides persistence, not a backup, authorization control, or full-VPS isolation.
