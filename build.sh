#!/usr/bin/env bash
# Bashan OS 1.0 build driver. Publisher: Bashan Tech LLC.
# Usage: ./build.sh {container|config|build|test|clean|status}
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

  log "ensuring build tools inside container"
  podman exec "$CONTAINER_NAME" sh -c '
    set -e
    command -v lb >/dev/null 2>&1 && exit 0
    apt-get update -qq
    apt-get install -y -qq live-build debian-archive-keyring xorriso squashfs-tools
  ' 2>&1 | tee -a "$LOG"
  podman exec "$CONTAINER_NAME" lb --version 2>&1 | tee -a "$LOG"
  log "container OK"
}

# Regenerate the live-build tree from packages/ hooks/ config/.
cmd_config() {
  need podman
  podman container exists "$CONTAINER_NAME" || die "no container; run: ./build.sh container"
  podman start "$CONTAINER_NAME" >/dev/null
  podman exec "$CONTAINER_NAME" bash /work/scripts/10-lb-config.sh 2>&1 | tee -a "$LOG"
}

cmd_in() {  # run a command inside the build container
  need podman
  podman container exists "$CONTAINER_NAME" || die "no container; run: ./build.sh container"
  podman start "$CONTAINER_NAME" >/dev/null
  podman exec -it "$CONTAINER_NAME" "$@"
}

# --- build / test / clean --------------------------------------------------
cmd_build() {
  need podman
  podman container exists "$CONTAINER_NAME" || die "no container; run: ./build.sh container"
  podman start "$CONTAINER_NAME" >/dev/null

  [ -d "$ROOT/build/work/lb/config" ] || die "no build tree; run: ./build.sh config"

  log "starting ISO build"
  log "free memory now: $(free -m | awk 'NR==2{print $7}') MB"

  # Run live-build in its three stages rather than as one "lb build", so the
  # chroot can be given real device nodes in between. A rootless container
  # cannot mknod, so without this /dev/null in the chroot is an ordinary
  # file and package configuration eventually fails. See
  # scripts/51-chroot-devices.sh for the full explanation.
  _stage() {
    local what="$1" cmd="$2"
    log "stage: $what"
    if ! podman exec "$CONTAINER_NAME" sh -c "$cmd" >>"$LOG" 2>&1; then
      log "stage '$what' FAILED - last 40 lines:"
      tail -40 "$LOG"
      podman exec "$CONTAINER_NAME" /work/scripts/51-chroot-devices.sh umount \
        >>"$LOG" 2>&1 || true
      die "build failed in '$what'; full log at $LOG"
    fi
  }

  _stage "bootstrap"      'cd /work/build/work/lb && lb bootstrap'
  _stage "device nodes"   '/work/scripts/51-chroot-devices.sh mount'
  _stage "chroot"         'cd /work/build/work/lb && lb chroot'
  _stage "release devices" '/work/scripts/51-chroot-devices.sh umount'
  _stage "binary"         'cd /work/build/work/lb && lb binary'
  log "live-build finished"

  iso=$(find "$ROOT/build/work/lb" -maxdepth 1 -name '*.iso' -o -maxdepth 1 -name '*.hybrid.iso' | head -1)
  [ -n "$iso" ] || die "build reported success but produced no .iso"

  mv "$iso" "$ROOT/build/out/$ISO_NAME"
  log "ISO: build/out/$ISO_NAME ($(du -h "$ROOT/build/out/$ISO_NAME" | cut -f1))"

  ( cd "$ROOT/build/out" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256" )
  log "SHA256: $(cut -d" " -f1 < "$ROOT/build/out/$ISO_NAME.sha256")"
}

cmd_test() {
  need shellcheck
  log "shellcheck on build.sh and scripts/"
  # shellcheck disable=SC2046  # intentional word splitting over found scripts
  shellcheck -x "$ROOT/build.sh" $(find "$ROOT/scripts" -name '*.sh' -print 2>/dev/null) \
    "$ROOT/theme/rootfs/usr/bin/bashan-theme-toggle" 2>&1 | tee -a "$LOG"
  log "shellcheck clean"

  # A light theme fails in exactly one way: a colour chosen for a dark
  # background stays in the palette and becomes unreadable text. This
  # measures every text/background pair in both variants against WCAG.
  log "palette contrast check (dark and light)"
  python3 "$ROOT/scripts/_palette.py" 2>&1 | tee -a "$LOG"
  log "contrast check passed"
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
  config)    cmd_config ;;
  in)        shift; cmd_in "$@" ;;
  build)     cmd_build ;;
  test)      cmd_test ;;
  clean)     cmd_clean ;;
  status)    cmd_status ;;
  *)         die "unknown target '$1' (container|config|in|build|test|clean|status)" ;;
esac
