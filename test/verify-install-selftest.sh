#!/bin/sh
# Self-check for bashan-verify-install, run by ./build.sh test.
#
# The contract: block ONLY on faults that leave a machine unusable, and
# warn about everything else. An earlier version failed a correct install
# over six legitimately removed packages, so both halves are asserted -
# that critical faults still stop an install, and that ordinary
# differences never do.
# shellcheck disable=SC2016  # crit's setup strings expand inside crit
set -eu
FIX=$(readlink -f "${1:-branding/rootfs/usr/libexec/bashan/bashan-verify-install}")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok    $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL  $1"; }
want() { d=$1; shift; if "$@"; then ok "$d"; else bad "$d"; fi; }

build_tree() {
    rm -rf "${tmp:?}/t"
    mkdir -p "$tmp/t/boot/grub" "$tmp/t/boot/efi/EFI/Bashan" "$tmp/t/etc/xdg" \
             "$tmp/t/usr/bin" "$tmp/t/usr/share/wayland-sessions" \
             "$tmp/t/usr/share/xsessions" "$tmp/t/usr/share/bashan" \
             "$tmp/t/etc/systemd/system/multi-user.target.wants"
    touch "$tmp/t/boot/vmlinuz-6.12.0-amd64"
    touch "$tmp/t/boot/efi/EFI/Bashan/shimx64.efi"
    printf 'UUID=abc / ext4 defaults 0 1\n' > "$tmp/t/etc/fstab"
    touch "$tmp/t/usr/bin/sddm"; chmod +x "$tmp/t/usr/bin/sddm"
    touch "$tmp/t/usr/share/wayland-sessions/plasma.desktop"
    printf 'root:x:0:0::/root:/bin/bash\ntestu:x:1000:1000::/home/testu:/bin/bash\n' \
        > "$tmp/t/etc/passwd"
    printf '[Daemon]\nAutolock=true\n' > "$tmp/t/etc/xdg/kscreenlockerrc"
    printf '[Wallet]\nEnabled=true\n'  > "$tmp/t/etc/xdg/kwalletrc"
    touch "$tmp/t/etc/systemd/system/multi-user.target.wants/unattended-upgrades.service"
    printf '%s\n' plasma-desktop sddm konsole dolphin kwin-wayland \
        | sort -u > "$tmp/t/installed-packages.txt"
    cp "$tmp/t/installed-packages.txt" "$tmp/t/usr/share/bashan/live-packages.txt"
    printf '%s\n' calamares live-boot > "$tmp/t/usr/share/bashan/expected-removals.txt"
}
run() { BASHAN_VERIFY_ROOT="$tmp/t" sh "$FIX" >"$tmp/out" 2>&1; }

echo "a healthy installed system"
build_tree
want "passes" run
want "says what it checked" grep -q "a user account" "$tmp/out"

echo "things that must NEVER fail an install"
# The exact case that failed a correct install: six legitimate removals.
build_tree
{ printf '%s\n' fonts-quicksand libyaml-cpp0.8 live-boot-doc live-config-doc \
      live-tools user-setup
  cat "$tmp/t/installed-packages.txt"; } | sort -u \
      > "$tmp/t/usr/share/bashan/live-packages.txt"
want "six removed packages do not fail it" run
want "but they are reported as a warning" grep -q "not installed" "$tmp/out"

build_tree
printf '%s\n' libfoo1 libbar2 libbaz3 zlib-extra qt6-spare gtk-spare \
    libquux9 libthing4 | cat - "$tmp/t/installed-packages.txt" | sort -u \
    > "$tmp/t/usr/share/bashan/live-packages.txt"
want "eight removed libraries do not fail it" run

# The manifest ships sorted at build time and the installed list is sorted
# at install time. If the two collations differ, comm walks past matching
# lines and invents missing packages - it once reported 471, libc6 among
# them, on a machine that was running fine.
build_tree
# python3-apt, python3.13 and python3-dev are enough to flip the order:
# byte order puts "-" before ".", en_US.UTF-8 does not, and comm then walks
# straight past matching lines. On the real 2373-package manifest the same
# mismatch invented 471 missing packages, libc6 and grep among them. The
# manifest is sorted when the image is built and the installed list when
# the install runs, so the two locales really can differ.
if locale -a 2>/dev/null | grep -qi "^en_US.utf8$"; then
    pkgs="plasma-desktop sddm konsole dolphin kwin-wayland python3-apt python3.13 python3-dev"
    # shellcheck disable=SC2086  # a deliberate word split over the names
    printf '%s\n' $pkgs | LC_ALL=C sort -u \
        > "$tmp/t/usr/share/bashan/live-packages.txt"
    # shellcheck disable=SC2086
    printf '%s\n' $pkgs > "$tmp/t/installed-packages.txt"
    if BASHAN_VERIFY_ROOT="$tmp/t" LC_ALL=en_US.UTF-8 sh "$FIX" >"$tmp/out" 2>&1; then
        ok "a manifest sorted under another locale does not fail it"
    else
        bad "a manifest sorted under another locale does not fail it"
    fi
    if grep -q "are not installed" "$tmp/out"; then
        bad "and invents no missing packages"
    else
        ok "and invents no missing packages"
    fi
else
    echo "  skip  sort-order case (en_US.UTF-8 not generated here)"
fi


build_tree; sed -i 's/^Autolock=true/Autolock=false/' "$tmp/t/etc/xdg/kscreenlockerrc"
want "no auto-lock does not fail it" run
want "but warns about it" grep -q "will not lock" "$tmp/out"

build_tree; sed -i 's/^Enabled=true/Enabled=false/' "$tmp/t/etc/xdg/kwalletrc"
want "disabled wallet does not fail it" run

build_tree
rm -f "$tmp/t/etc/systemd/system/multi-user.target.wants/unattended-upgrades.service"
want "updates off does not fail it" run

echo "things that MUST fail an install"
# Each case gets a one-line setup, run as a string so $tmp expands in crit.
crit() { # description, setup
    d=$1; setup=$2
    build_tree; eval "$setup"
    if run; then bad "$d"; else ok "$d"; fi
}
crit "no kernel"            'rm -f "$tmp/t/boot/vmlinuz-6.12.0-amd64"'
crit "no bootloader"        'rm -f "$tmp/t/boot/efi/EFI/Bashan/shimx64.efi"'
crit "empty fstab"          ': > "$tmp/t/etc/fstab"'
crit "fstab has no root"    'printf "UUID=abc /home ext4 defaults 0 2\n" > "$tmp/t/etc/fstab"'
crit "no sddm"              'rm -f "$tmp/t/usr/bin/sddm"'
crit "no desktop session"   'rm -f "$tmp/t/usr/share/wayland-sessions/plasma.desktop"'
crit "no user account"      'printf "root:x:0:0::/root:/bin/bash\n" > "$tmp/t/etc/passwd"'
crit "only a system account" 'printf "root:x:0:0::/root:/bin/bash\nsddm:x:106:110::/var/lib/sddm:/usr/sbin/nologin\n" > "$tmp/t/etc/passwd"'

build_tree; rm -f "$tmp/t/boot/vmlinuz-6.12.0-amd64"; run || true
want "a critical failure says the machine would not start" \
    grep -q "would not start" "$tmp/out"

echo ""
echo "  $pass passed, $fail failed"
[ "$fail" = 0 ]
