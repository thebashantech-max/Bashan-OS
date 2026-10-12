#!/bin/sh
# Bashan OS — give the build chroot real device nodes.
#
# WHY THIS EXISTS
# A rootless container cannot call mknod, so when live-build bootstraps the
# chroot it cannot create /dev/null, /dev/zero and friends. debootstrap
# falls back to leaving an ordinary empty FILE called "null" in its place.
#
# Almost everything survives that, which is what makes it nasty: hundreds of
# maintainer scripts redirect to /dev/null and simply write into the file
# instead. The first thing that actually breaks is aspell-autobuildhash,
# which hands /dev/null to aspell as a config file and gets a parse error,
# failing the whole build on dictionaries-common.
#
# mknod is blocked, but bind-mounting is not, so we bind the container's own
# device nodes over the placeholders. They are unmounted again before the
# squashfs is made; the installed system gets its real /dev from devtmpfs at
# boot, so nothing needs to be baked in.
set -eu

CHROOT="${2:-/work/build/work/lb/chroot}"
DEVICES="null zero full random urandom tty"

case "${1:-}" in
mount)
    [ -d "$CHROOT/dev" ] || { echo "E: no $CHROOT/dev" >&2; exit 1; }
    for d in $DEVICES; do
        [ -e "/dev/$d" ] || continue
        # A bind mount needs an existing target of any type.
        [ -e "$CHROOT/dev/$d" ] || : > "$CHROOT/dev/$d"
        if mountpoint -q "$CHROOT/dev/$d" 2>/dev/null; then
            continue
        fi
        mount --bind "/dev/$d" "$CHROOT/dev/$d"
    done
    echo "I: bound device nodes into the chroot:"
    for d in $DEVICES; do
        [ -e "$CHROOT/dev/$d" ] && printf '     %s\n' "$(ls -l "$CHROOT/dev/$d")"
    done
    ;;
umount)
    # Reverse order, and never fail: this also runs on the error path.
    for d in $DEVICES; do
        if mountpoint -q "$CHROOT/dev/$d" 2>/dev/null; then
            umount "$CHROOT/dev/$d" || true
        fi
    done
    echo "I: device binds released"
    ;;
*)
    echo "usage: $0 {mount|umount} [chroot-path]" >&2
    exit 1
    ;;
esac
