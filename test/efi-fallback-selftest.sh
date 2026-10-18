#!/bin/sh
# Self-check for bashan-fix-efi-fallback, run by ./build.sh test.
#
# It builds a fake ESP that reproduces exactly what install attempt 3
# produced, runs the repair against it, and asserts the result would boot.
# Then it corrupts the result two ways and asserts the verification CATCHES
# each one -- a check that cannot fail is worse than no check, which is the
# mistake the UTF-16 CSV grep made.
#
# The NVRAM half cannot be tested here: it needs a real efivarfs. Only the
# file-layout half is covered.
set -eu

FIX=${1:-branding/rootfs/usr/libexec/bashan/bashan-fix-efi-fallback}
[ -x "$FIX" ] || { echo "E: $FIX not executable"; exit 1; }
FIX=$(readlink -f "$FIX")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
# want <description> <command...>
want() { d=$1; shift; if "$@"; then ok "$d"; else bad "$d"; fi; }

# Attempt 3's ESP, byte sizes and all.
build_esp() {
    rm -rf "$tmp/esp"; mkdir -p "$tmp/esp/EFI/Bashan" "$tmp/esp/EFI/BOOT"
    s="$tmp/esp/EFI/Bashan"
    truncate -s 1036152 "$s/shimx64.efi"
    truncate -s 2684352 "$s/grubx64.efi"
    truncate -s  873904 "$s/mmx64.efi"
    truncate -s  118832 "$s/fbx64.efi"
    printf 'shimx64.efi,debian,,This is the boot entry for debian\n' \
        | iconv -f UTF-8 -t UTF-16LE > "$s/BOOTX64.CSV"
    printf "search.fs_uuid 01b16441-3047-478b-90ef-b8cc29f6070f root \nset prefix=(\$root)'/boot/grub'\nconfigfile \$prefix/grub.cfg\n" > "$s/grub.cfg"
    # The fault: Calamares put GRUB at the removable path.
    cp "$s/grubx64.efi" "$tmp/esp/EFI/BOOT/bootx64.efi"
}

echo "repair a attempt-3 ESP"
build_esp
if BASHAN_ESP="$tmp/esp" sh "$FIX" >"$tmp/out" 2>&1; then
    ok "repair succeeded"
else
    bad "repair failed: $(cat "$tmp/out")"
fi
b="$tmp/esp/EFI/BOOT"
want "removable path is shim, not grub" \
    test "$(stat -c %s "$b/BOOTX64.EFI")" = 1036152
for f in grubx64.efi mmx64.efi fbx64.efi BOOTX64.CSV grub.cfg; do
    want "shim's companion present: $f" test -s "$b/$f"
done
want "baked-in prefix /EFI/debian/grub.cfg exists" test -s "$tmp/esp/EFI/debian/grub.cfg"
want "prefix config can still find root" \
    grep -q 'search.fs_uuid' "$tmp/esp/EFI/debian/grub.cfg"
csv=$(iconv -f UTF-16LE -t UTF-8 < "$b/BOOTX64.CSV")
case "$csv" in *"Bashan OS"*) ok "recovery CSV says Bashan OS" ;; *) bad "CSV: $csv" ;; esac
case "$csv" in *[Dd]ebian*) bad "CSV still branded debian" ;; *) ok "no debian branding in CSV" ;; esac

# A check that cannot fail is not a check. Prove each one bites.
echo "verification catches a bad ESP"
build_esp
BASHAN_ESP="$tmp/esp" sh "$FIX" >/dev/null 2>&1
cp "$tmp/esp/EFI/Bashan/grubx64.efi" "$tmp/esp/EFI/BOOT/BOOTX64.EFI"
BASHAN_ESP="$tmp/esp" sh "$FIX" >"$tmp/out" 2>&1
# The repair re-copies shim, so re-running must heal it rather than pass a lie.
want "re-running heals a grub-sized fallback" \
    test "$(stat -c %s "$tmp/esp/EFI/BOOT/BOOTX64.EFI")" = 1036152

build_esp
rm -f "$tmp/esp/EFI/Bashan/shimx64.efi"
if BASHAN_ESP="$tmp/esp" sh "$FIX" >"$tmp/out" 2>&1; then
    bad "accepted an ESP with no shim at all"
else
    ok "refuses an ESP with no shim"
fi

echo "legacy BIOS install"
rm -rf "$tmp/esp"; mkdir -p "$tmp/esp"
if BASHAN_ESP="$tmp/esp" sh "$FIX" >"$tmp/out" 2>&1 && grep -q 'legacy boot' "$tmp/out"; then
    ok "skips cleanly with no ESP"
else
    bad "did not skip on a BIOS install: $(cat "$tmp/out")"
fi

echo
echo "  $pass passed, $fail failed"
[ "$fail" = 0 ]
