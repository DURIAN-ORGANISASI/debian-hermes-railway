#!/usr/bin/env bash
set -Eeuo pipefail
: "${TERMINAL_USER:?Set TERMINAL_USER in Railway Variables}"
: "${TERMINAL_PASSWORD:?Set TERMINAL_PASSWORD in Railway Variables}"

if [[ "${TERMINAL_USER}" == *:* ]]; then echo "ERROR: TERMINAL_USER must not contain a colon (:)." >&2; exit 1; fi
if [[ ${#TERMINAL_PASSWORD} -lt 16 ]]; then echo "ERROR: TERMINAL_PASSWORD must be at least 16 characters." >&2; exit 1; fi

PORT="${PORT:-8080}"
HERMES_HOME="${HERMES_HOME:-/opt/data}"
HERMES_RUNTIME_DIR="${HERMES_RUNTIME_DIR:-/usr/local/share/hermes-tools}"
UV_CACHE_DIR="${UV_CACHE_DIR:-/tmp/uv-cache}"
export TZ="${TZ:-Asia/Jakarta}" HOME=/home/hermes USER=hermes LOGNAME=hermes
export PATH="/home/hermes/.local/bin:/home/hermes/.local/share/uv/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HERMES_HOME HERMES_RUNTIME_DIR UV_CACHE_DIR

# Fixed paths prevent accidental ownership changes outside the intended data locations.
[[ "${HERMES_HOME}" == "/opt/data" ]] || { echo "ERROR: HERMES_HOME must be /opt/data." >&2; exit 1; }
[[ "${HERMES_RUNTIME_DIR}" == "/usr/local/share/hermes-tools" ]] || { echo "ERROR: HERMES_RUNTIME_DIR must be /usr/local/share/hermes-tools." >&2; exit 1; }
[[ "${UV_CACHE_DIR}" == "/tmp/uv-cache" ]] || { echo "ERROR: UV_CACHE_DIR must be /tmp/uv-cache." >&2; exit 1; }
if [[ ! "${PORT}" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then echo "ERROR: PORT must be a TCP port number." >&2; exit 1; fi
if [[ -L "${HERMES_HOME}" || -L "${HERMES_RUNTIME_DIR}" || -L "${UV_CACHE_DIR}" ]]; then echo "ERROR: Hermes data/runtime/cache roots must not be symlinks." >&2; exit 1; fi

mkdir -p "${HERMES_HOME}" "${HERMES_RUNTIME_DIR}" "${UV_CACHE_DIR}" /data /home/hermes

# Preserve the source directory unless copying every file succeeds.
relocate_rebuildable_dir() {
  local persistent="$1" runtime="$2" target
  mkdir -p "$(dirname "${persistent}")" "$(dirname "${runtime}")"
  if [[ -L "${persistent}" ]]; then
    target="$(readlink "${persistent}")"
    [[ "${target}" == "${runtime}" ]] && { mkdir -p "${runtime}"; return 0; }
    echo "ERROR: ${persistent} points to unexpected symlink target: ${target}" >&2
    return 1
  fi
  if [[ -d "${persistent}" ]]; then
    mkdir -p "${runtime}"
    cp -a "${persistent}/." "${runtime}/" || { echo "ERROR: Copy failed; original ${persistent} was kept." >&2; return 1; }
    rm -rf "${persistent}"
  elif [[ -e "${persistent}" ]]; then
    echo "ERROR: ${persistent} exists but is not a directory." >&2
    return 1
  else
    mkdir -p "${runtime}"
  fi
  ln -s "${runtime}" "${persistent}"
}

relocate_rebuildable_dir "${HERMES_HOME}/cache/partials" "${HERMES_RUNTIME_DIR}/cache/partials"
relocate_rebuildable_dir "${HERMES_HOME}/tools" "${HERMES_RUNTIME_DIR}/tools"
relocate_rebuildable_dir "${HERMES_HOME}/cache/uv" "${HERMES_RUNTIME_DIR}/cache/uv"
relocate_rebuildable_dir "${HERMES_HOME}/installs" "${HERMES_RUNTIME_DIR}/installs"

# Mark completed ownership migration so later restarts do not repeatedly scan large Volumes.
migrate_volume_ownership() {
  local directory="$1" marker="${1}/.railway-uid-10001" marker_uid=""
  if [[ -L "${marker}" ]]; then echo "ERROR: Unexpected migration marker symlink: ${marker}" >&2; return 1; fi
  [[ -f "${marker}" ]] && marker_uid="$(stat -c '%u' "${marker}")"
  if [[ "${marker_uid}" == "10001" && "$(stat -c '%u' "${directory}")" == "10001" ]]; then return 0; fi
  echo "Migrating ownership of ${directory} to UID/GID 10001; large Volumes may take longer."
  chown -R --no-dereference hermes:hermes "${directory}"
  install -o hermes -g hermes -m 0600 /dev/null "${marker}"
}

migrate_volume_ownership "${HERMES_HOME}"
migrate_volume_ownership "${HERMES_RUNTIME_DIR}"
migrate_volume_ownership /data
chmod 0700 "${HERMES_HOME}" /home/hermes "${UV_CACHE_DIR}"
chmod 0770 /data
chmod 0750 "${HERMES_RUNTIME_DIR}"

echo "Starting Debian 13 + Hermes terminal as non-root UID 10001 on port ${PORT}."
echo "Hermes data remains at ${HERMES_HOME}; rebuildable tools stay outside the Volume."
exec /usr/bin/setpriv --reuid=hermes --regid=hermes --init-groups /usr/bin/python3 /usr/local/bin/service-supervisor.py
