# Contributing

Thanks for helping improve Debian + Hermes Agent Railway.

## Guidelines

- Keep changes focused and explain their purpose.
- Keep documentation consistent with `Dockerfile`, `entrypoint.sh`, `start-hermes`, `system-banner.sh`, and the CI workflow.
- Do not commit terminal passwords, bot tokens, API keys, provider credentials, private configuration, or logs containing secrets.
- If changing upstream components or logos, update `docs/SOURCES.md` and review the relevant license terms.
- Keep examples explicit about platform limitations: this project runs as a Railway application container, not a full VPS.

## Validation

Where possible, run these checks before opening a pull request:

```bash
bash -n entrypoint.sh
bash -n start-hermes
bash -n system-banner.sh
docker build --tag debian-hermes-railway .
```

GitHub Actions also checks shell syntax, builds the image, and runs a terminal authentication smoke test. A passing workflow does not prove that the live Railway service has been configured or deployed correctly.

## Pull requests

Describe what changed, why it changed, and what was tested. Remove secrets from all screenshots, logs, and example files.
