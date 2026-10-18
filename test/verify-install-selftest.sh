#!/bin/sh
# Self-check for bashan-verify-install, run by ./build.sh test.
#
# Builds fake installed trees and asserts the verifier passes a healthy one
# and FAILS each way attempt 4 actually failed. A check that cannot fail is
# worse than no check.
set -eu

FIX=${1:-branding/rootfs/usr/libexec/bashan/bashan-verify-install}
[ -x "$FIX" ] || { echo "E: $FIX not executable"; exit 1; }
FIX=$(readlink -f "$FIX")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
want() { d=$1; shift; if "$@"; then ok "$d"; else bad "$d"; fi; }

# A healthy target: sessions, sddm, and only the intended removals gone.
build_tree() {
    rm -rf "$tmp/t"
    mkdir -p "$tmp/t/usr/share/xsessions" "$tmp/t/usr/share/wayland-sessions" \
             "$tmp/t/usr/share/bashan" "$tmp/t/usr/bin"
    touch "$tmp/t/usr/share/wayland-sessions/plasma.desktop"
    touch "$tmp/t/usr/bin/sddm"; chmod +x "$tmp/t/usr/bin/sddm"
    mkdir -p "$tmp/t/etc/xdg" \
             "$tmp/t/etc/systemd/system/multi-user.target.wants"
    printf '[Daemon]\nAutolock=true\nTimeout=10\n' > "$tmp/t/etc/xdg/kscreenlockerrc"
    printf '[Wallet]\nEnabled=true\n' > "$tmp/t/etc/xdg/kwalletrc"
    touch "$tmp/t/etc/systemd/system/multi-user.target.wants/unattended-upgrades.service"
    # Roughly the shape of a real Plasma install, so that removing the
    # desktop produces the double-figure casualty list it does in reality.
    DESKTOP='plasma-desktop plasma-workspace plasma-integration breeze
             qml6-module-qtquick-controls kwin-wayland kwin-x11 systemsettings
             plasma-systemmonitor kde-config-screenlocker sddm konsole dolphin'
    # shellcheck disable=SC2086
    printf '%s\n' calamares live-boot live-config $DESKTOP \
        | sort -u > "$tmp/t/usr/share/bashan/live-packages.txt"
    printf '%s\n' calamares calamares-settings-debian live-boot \
        live-boot-initramfs-tools live-config live-config-systemd \
        > "$tmp/t/usr/share/bashan/expected-removals.txt"
    # What survived: everything but the intended removals.
    # shellcheck disable=SC2086
    printf '%s\n' $DESKTOP | sort -u > "$tmp/t/installed-packages.txt"
}
run() { BASHAN_VERIFY_ROOT="$tmp/t" sh "$FIX" >"$tmp/out" 2>&1; }

echo "a healthy installed system"
build_tree
want "passes" run
want "reports no unexpected removals" grep -q "no unexpected package removals" "$tmp/out"

echo "attempt 4's actual failure: the desktop was removed"
build_tree
rm -rf "$tmp/t/usr/share/xsessions" "$tmp/t/usr/share/wayland-sessions"
printf '%s\n' sddm konsole dolphin | sort -u > "$tmp/t/installed-packages.txt"
if run; then bad "accepted a system with no desktop session"; else ok "refuses a system with no session"; fi
want "says nobody could log in" grep -q "nobody could log in" "$tmp/out"
want "names the cascade" grep -q "cascaded" "$tmp/out"
want "lists plasma-desktop as missing" grep -q "plasma-desktop" "$tmp/out"

echo "a missing greeter"
build_tree
rm -f "$tmp/t/usr/bin/sddm"
if run; then bad "accepted a system with no sddm"; else ok "refuses a system with no greeter"; fi

echo "a few missing packages stay under the tolerance"
build_tree
grep -vxE 'breeze|systemsettings' "$tmp/t/installed-packages.txt" > "$tmp/i" \
    && mv "$tmp/i" "$tmp/t/installed-packages.txt"
want "tolerates two extra removals" run
want "still lists them as a warning" grep -q "missing after install" "$tmp/out"

echo "live-only settings must not survive the install"
build_tree
sed -i 's/^Autolock=true/Autolock=false/' "$tmp/t/etc/xdg/kscreenlockerrc"
if run; then bad "accepted a system that never locks"; else ok "refuses Autolock=false"; fi
want "says it would never lock" grep -q "would never lock" "$tmp/out"

build_tree
sed -i 's/^Enabled=true/Enabled=false/' "$tmp/t/etc/xdg/kwalletrc"
if run; then bad "accepted a disabled wallet"; else ok "refuses a disabled KWallet"; fi

build_tree
mkdir -p "$tmp/t/lib/live/config"; touch "$tmp/t/lib/live/config/2000-bashan-live"
if run; then bad "accepted leftover live-only config"; else ok "refuses leftover live-only config"; fi

build_tree
rm -f "$tmp/t/etc/systemd/system/multi-user.target.wants/unattended-upgrades.service"
if run; then bad "accepted disabled security updates"; else ok "refuses disabled security updates"; fi

echo "a missing manifest is itself a failure"
build_tree
rm -f "$tmp/t/usr/share/bashan/live-packages.txt"
if run; then bad "accepted a target with no manifest"; else ok "refuses when the manifest is absent"; fi

echo
echo "  $pass passed, $fail failed"
[ "$fail" = 0 ]
