#!/usr/bin/env bash
# Bashan OS 1.0 build driver. Publisher: Bashan Tech LLC.
# Usage: ./build.sh {container|build|test|clean|status}
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config/build.conf
source "$ROOT/config/build.conf"

LOG_DIR="$ROOT/build/logs"
mkdir -p "$LOG_DIR" "$ROOT/build/work" "$ROOT/build/out"
LOG="$LOG_DIR/$(date +%Y%m%d-%H%M%S)-${1:-noop}.log"

log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }
die()  { printf '[%s] ERROR: %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "missing host tool: $1"; }

# --- container -------------------------------------------------------------
# Idempotent: creates the trixie build container only if it is not there,
# then proves it can run and reach the Debian archive.
cmd_container() {
  need podman
  log "using image $CONTAINER_IMAGE"
  podman image exists "$CONTAINER_IMAGE" || podman pull "$CONTAINER_IMAGE" 2>&1 | tee -a "$LOG"

  if podman container exists "$CONTAINER_NAME"; then
    log "container $CONTAINER_NAME already exists, reusing"
  else
    log "creating container $CONTAINER_NAME"
    podman create --name "$CONTAINER_NAME" \
      --privileged \
      -v "$ROOT:/work:Z" \
      -w /work \
      "$CONTAINER_IMAGE" sleep infinity 2>&1 | tee -a "$LOG"
  fi

  podman start "$CONTAINER_NAME" >/dev/null
  log "verifying container"
  podman exec "$CONTAINER_NAME" sh -c '. /etc/os-release; echo "inside: $PRETTY_NAME"; id -u' 2>&1 | tee -a "$LOG"
  podman exec "$CONTAINER_NAME" sh -c 'test -d /work/config' \
    || die "project not mounted at /work inside container"
  log "container OK"
}

cmd_in() {  # run a command inside the build container
  need podman
  podman container exists "$CONTAINER_NAME" || die "no container; run: ./build.sh container"
  podman start "$CONTAINER_NAME" >/dev/null
  podman exec -it "$CONTAINER_NAME" "$@"
}

# --- build / test / clean --------------------------------------------------
cmd_build() {
  die "ISO build lands in Stage 9. Stages 3-8 must be approved first."
}

cmd_test() {
  need shellcheck
  log "shellcheck on build.sh and scripts/"
  # shellcheck disable=SC2046  # intentional word splitting over found scripts
  shellcheck -x "$ROOT/build.sh" $(find "$ROOT/scripts" -name '*.sh' -print 2>/dev/null) 2>&1 | tee -a "$LOG"
  log "shellcheck clean"
}

cmd_clean() {
  log "removing build/work and build/out (logs kept)"
  rm -rf "${ROOT:?}/build/work" "${ROOT:?}/build/out"
  mkdir -p "$ROOT/build/work" "$ROOT/build/out"
  log "clean done"
}

cmd_status() {
  printf '%s %s (%s) — %s\n' "$OS_NAME" "$OS_VERSION" "$OS_ID" "$OS_PUBLISHER"
  printf 'base: debian %s/%s   iso: %s\n' "$SUITE" "$ARCH" "$ISO_NAME"
  if command -v podman >/dev/null 2>&1 && podman container exists "$CONTAINER_NAME"; then
    printf 'container: %s (%s)\n' "$CONTAINER_NAME" "$(podman inspect -f '{{.State.Status}}' "$CONTAINER_NAME")"
  else
    printf 'container: not created\n'
  fi
}

case "${1:-status}" in
  container) cmd_container ;;
  in)        shift; cmd_in "$@" ;;
  build)     cmd_build ;;
  test)      cmd_test ;;
  clean)     cmd_clean ;;
  status)    cmd_status ;;
  *)         die "unknown target '$1' (container|in|build|test|clean|status)" ;;
esac
