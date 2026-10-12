#!/usr/bin/env bash
# Bashan OS — generate the live-build tree from this repository.
# Runs INSIDE the trixie container (live-build is never on the host).
# Idempotent: wipes and regenerates build/work/lb on every run.
set -Eeuo pipefail

ROOT="${BASHAN_ROOT:-/work}"
# shellcheck source-path=SCRIPTDIR/..
# shellcheck source=config/build.conf
source "$ROOT/config/build.conf"

LB_DIR="$ROOT/build/work/lb"

command -v lb >/dev/null 2>&1 || {
  echo "E: live-build not installed in this container." >&2
  echo "   run: apt-get install -y live-build" >&2
  exit 1
}

echo "I: regenerating live-build tree at $LB_DIR"
rm -rf "$LB_DIR"
mkdir -p "$LB_DIR"
cd "$LB_DIR"

lb config \
  --mode debian \
  --distribution "$SUITE" \
  --architectures "$ARCH" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap "$MIRROR" \
  --mirror-binary "$MIRROR" \
  --security true \
  --updates true \
  --binary-images iso-hybrid \
  --bootloaders "grub-efi,syslinux" \
  --debian-installer none \
  --firmware-binary true \
  --firmware-chroot true \
  --linux-packages linux-image \
  --memtest none \
  --apt-indices false \
  --cache-packages true \
  --iso-application "$OS_NAME" \
  --iso-publisher "$OS_PUBLISHER" \
  --iso-volume "$OS_NAME $OS_VERSION" \
  --iso-preparer "$OS_PUBLISHER"

# --- graft this repository's sources into the live-build tree -------------
mkdir -p config/package-lists config/hooks/normal config/includes.chroot

echo "I: package lists"
for f in "$ROOT"/packages/*.list.chroot; do
  [ -e "$f" ] || continue
  cp -v "$f" config/package-lists/
done

echo "I: third-party archives (Brave build-time + in-image, Chrome in-image only)"
if [ -d "$ROOT/config/archives" ]; then
  mkdir -p config/archives
  for f in "$ROOT"/config/archives/*; do
    [ -e "$f" ] || continue
    cp -v "$f" config/archives/
  done
fi

echo "I: chroot hooks"
for f in "$ROOT"/hooks/chroot/*.hook.chroot; do
  [ -e "$f" ] || continue
  install -m 0755 -v "$f" config/hooks/normal/
done

echo "I: rootfs overlay"
if [ -d "$ROOT/hooks/rootfs" ]; then
  cp -a "$ROOT/hooks/rootfs/." config/includes.chroot/
  find config/includes.chroot -type f | sed 's|^config/includes.chroot|  /|'
fi

echo "I: live-build tree ready"
