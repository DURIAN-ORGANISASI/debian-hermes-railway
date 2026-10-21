# Sources, attribution, and license

This document records the upstream projects, logos, illustrations, and licensing boundaries used by Debian + Hermes Agent Railway.

## Core components

- **Debian 13 (Trixie):** official container base image `debian:trixie-slim`. Project: https://www.debian.org/ — official image: https://hub.docker.com/_/debian
- **Hermes Agent:** https://github.com/NousResearch/hermes-agent — official documentation: https://hermes-agent.nousresearch.com/docs/getting-started/installation
- **ttyd 1.7.7:** https://github.com/tsl0922/ttyd — terminal binary is fetched from the upstream GitHub Releases for AMD64 or ARM64; its own license remains applicable.
- **Railway:** https://railway.com/ — deployment, networking, and volume service, subject to Railway's terms.
- **Docker:** https://www.docker.com/ — image build and container runtime technology.

## Logos and attribution

### Debian

The header uses the Debian Project's official open-use logo: https://www.debian.org/logos/openlogo-nd.svg

Debian's official logo guidance identifies the open-use logo as the preferred logo for referring to Debian. The logo is Copyright © 1999 Software in the Public Interest, Inc. and is released under LGPL v3 or later, or alternatively CC BY-SA 3.0 Unported. Details: https://www.debian.org/logos/

The logo links to https://www.debian.org/ in accordance with the official guidance. Its use identifies the container's base distribution and does not imply Debian endorsement.

### Hermes Agent

The header uses the Hermes Agent favicon from the upstream project:
https://raw.githubusercontent.com/NousResearch/hermes-agent/main/website/static/img/favicon.svg

Project source and licensing: https://github.com/NousResearch/hermes-agent. Its name and branding identify the upstream software; this repository is not represented as an official NousResearch project.

## Original documentation artwork

The following SVG illustrations were created for this repository and are not screenshots of live products:

- `docs/hero.id.svg`
- `docs/hero.en.svg`
- `docs/architecture.svg`
- `docs/architecture.en.svg`

They explain the intended deployment model and do not guarantee a particular live service state.

## License scope

Project files and original artwork covered by the root `LICENSE` are released under the MIT License.

The root MIT license does not replace or override the licenses and terms for Debian's logo, Hermes Agent, ttyd, Debian packages, Railway, Docker, or any other third-party components. Each upstream project and service remains subject to its own terms.
