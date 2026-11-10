# syntax=docker/dockerfile:1.7
FROM debian:trixie-slim
ARG DEBIAN_FRONTEND=noninteractive
ARG TTYD_VERSION=1.7.7
ARG HERMES_VERSION=0.23.1
ARG HERMES_COMMIT=3b421578588243f920886e6fe79a6faa87ea026e
ARG TARGETARCH

ENV TZ=Asia/Jakarta \
    PORT=8080 \
    HOME=/home/hermes \
    USER=hermes \
    LOGNAME=hermes \
    PATH="/home/hermes/.local/bin:/home/hermes/.local/share/uv/bin:/usr/local/bin:/usr/bin:/bin" \
    HERMES_HOME=/opt/data \
    HERMES_RUNTIME_DIR=/usr/local/share/hermes-tools \
    UV_CACHE_DIR=/tmp/uv-cache \
    HERMES_AUTOSTART=true \
    HERMES_VERSION=${HERMES_VERSION}

# BuildKit cache mounts reduce repeated apt downloads between image builds.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl coreutils procps sed git tar tzdata libatomic1 \
    python3 python3-venv python3-pip \
    build-essential pkg-config libffi-dev libssl-dev xz-utils \
    passwd util-linux \
    && (apt-get install -y --no-install-recommends fastfetch || true) \
    && ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
    && printf '%s\n' "${TZ}" > /etc/timezone \
    && groupadd --gid 10001 hermes \
    && useradd --uid 10001 --gid 10001 --create-home --home-dir /home/hermes --shell /bin/bash hermes \
    && install -d --owner=hermes --group=hermes --mode=0700 /opt/data /home/hermes /tmp/uv-cache \
    && install -d --owner=hermes --group=hermes --mode=0770 /data \
    && install -d --owner=hermes --group=hermes --mode=0750 /usr/local/share/hermes-tools /usr/local/share/hermes-agent \
    && install -d --owner=hermes --group=hermes --mode=0750 /usr/local/share/hermes-tools/installs \
    && install -d --owner=hermes --group=hermes --mode=0750 /usr/local/share/hermes-tools/cache/uv \
    && install -d --owner=hermes --group=hermes --mode=0750 /usr/local/share/hermes-tools/cache/partials \
    && install -d --owner=hermes --group=hermes --mode=0750 /usr/local/share/hermes-tools/tools \
    && install -d --owner=hermes --group=hermes --mode=0700 /opt/data/cache \
    && ln -s /usr/local/share/hermes-tools/installs /opt/data/installs \
    && ln -s /usr/local/share/hermes-tools/cache/uv /opt/data/cache/uv \
    && ln -s /usr/local/share/hermes-tools/cache/partials /opt/data/cache/partials \
    && ln -s /usr/local/share/hermes-tools/tools /opt/data/tools

# Fetch ttyd for the requested target architecture.
RUN set -eux; \
    case "${TARGETARCH:-amd64}" in \
      amd64) TTYD_ASSET="ttyd.x86_64" ;; \
      arm64) TTYD_ASSET="ttyd.aarch64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl --retry 8 --retry-all-errors --retry-delay 3 --retry-max-time 120 -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/${TTYD_ASSET}" -o /usr/local/bin/ttyd; \
    chmod 0755 /usr/local/bin/ttyd; \
    /usr/local/bin/ttyd --version

# Install the pinned Hermes release as the dedicated service user, not root.
USER hermes
RUN --mount=type=cache,target=/tmp/uv-cache,uid=10001,gid=10001,sharing=locked \
    set -eux; \
    curl --retry 8 --retry-all-errors --retry-delay 3 --retry-max-time 120 -fsSL "https://raw.githubusercontent.com/NousResearch/hermes-agent/${HERMES_COMMIT}/scripts/install.sh" -o /tmp/install-hermes.sh; \
    bash /tmp/install-hermes.sh --commit "${HERMES_COMMIT}" --dir /usr/local/share/hermes-agent --hermes-home "${HERMES_HOME}" --non-interactive --skip-browser; \
    command -v hermes; \
    hermes --version; \
    hermes pm install --extra messaging --extra telegram --extra discord; \
    hermes pm doctor; \
    rm -f /tmp/install-hermes.sh

USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY service-supervisor.py /usr/local/bin/service-supervisor.py
COPY system-banner.sh /etc/profile.d/00-system-banner.sh
COPY start-hermes /usr/local/bin/start-hermes

RUN chmod 0755 /usr/local/bin/entrypoint.sh /usr/local/bin/service-supervisor.py /usr/local/bin/start-hermes /etc/profile.d/00-system-banner.sh \
    && bash -n /usr/local/bin/entrypoint.sh /usr/local/bin/start-hermes /etc/profile.d/00-system-banner.sh \
    && python3 -m py_compile /usr/local/bin/service-supervisor.py \
    && chown -R --no-dereference hermes:hermes /opt/data /usr/local/share/hermes-tools /usr/local/share/hermes-agent /home/hermes /tmp/uv-cache /data \
    && chmod 0700 /opt/data /home/hermes /tmp/uv-cache \
    && chmod 0770 /data \
    && chmod 0750 /usr/local/share/hermes-tools /usr/local/share/hermes-agent

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
