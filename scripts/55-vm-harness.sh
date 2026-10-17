#!/usr/bin/env bash
# Bashan OS — host side of the TEST-ONLY VM harness.
#
#   ./scripts/55-vm-harness.sh make        build the shared disk
#   ./scripts/55-vm-harness.sh read        read results back out
#   ./scripts/55-vm-harness.sh put FILE    add another script to the disk
#
# A small FAT image carrying test scripts, attached to the VM as an extra
# drive. The guest mounts it, runs a script, writes results to it; the host
# reads them with mtools, which needs no root and no loop device.
#
# This replaces driving the guest by typing characters at QEMU's monitor.
# That channel drops keys on anything long, so a diagnostic could appear to
# run and quietly report something other than what was asked.
#
# NOTHING HERE GOES INTO THE ISO. hooks/chroot/0930-no-test-harness.hook.chroot
# fails the build if it does.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMG="$ROOT/build/vm/harness.img"
SRC="$ROOT/test/vm-harness"

die() { echo "E: $*" >&2; exit 1; }

cmd_make() {
  command -v mkfs.vfat >/dev/null || die "need dosfstools"
  command -v mcopy >/dev/null     || die "need mtools"
  mkdir -p "$(dirname "$IMG")"
  rm -f "$IMG"
  truncate -s 16M "$IMG"
  mkfs.vfat -F 16 -n BASHANTEST "$IMG" >/dev/null
  for f in "$SRC"/*.sh; do
    [ -e "$f" ] || continue
    mcopy -i "$IMG" "$f" "::$(basename "$f")"
  done
  # A deliberately SHORT entry point: every character of the command that
  # starts this has to be typed through QEMU's monitor by hand.
  printf '#!/bin/sh\nsh /mnt/bashan-test/run-checks.sh\n' > "$ROOT/build/vm/.r.sh"
  mcopy -i "$IMG" "$ROOT/build/vm/.r.sh" ::r.sh
  rm -f "$ROOT/build/vm/.r.sh"
  echo "I: $IMG built, contents:"
  mdir -i "$IMG" :: | sed 's/^/   /'
  echo
  echo "I: in the guest, one short command does everything:"
  echo "     sudo mkdir -p /mnt/bashan-test && sudo mount /dev/vdb /mnt/bashan-test && sudo sh /mnt/bashan-test/r.sh"
}

cmd_read() {
  [ -f "$IMG" ] || die "no $IMG - run: $0 make"
  mcopy -i "$IMG" ::results.txt - 2>/dev/null \
    || die "no results.txt on the harness disk yet"
}

cmd_put() {
  [ -f "${1:-}" ] || die "usage: $0 put FILE"
  mcopy -i "$IMG" -o "$1" "::$(basename "$1")"
  echo "I: added $(basename "$1")"
}

case "${1:-}" in
  make) cmd_make ;;
  read) cmd_read ;;
  put)  shift; cmd_put "$@" ;;
  *)    die "usage: $0 {make|read|put FILE}" ;;
esac
