#!/bin/sh
# Self-check for 0960-public-release.hook.chroot, run by ./build.sh test.
#
# The point of that hook is that it looks at the IMAGE, not at two variables
# in build.conf. These cases put a song and unconfirmed artwork into a fake
# image and prove the build stops.
set -eu
HOOK=$(readlink -f "${1:-hooks/chroot/0960-public-release.hook.chroot}")
LISTSRC=$(readlink -f config/unconfirmed-assets.sha256)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
want() { d=$1; shift; if "$@"; then ok "$d"; else bad "$d"; fi; }

# public=yes|no, placeholders=yes|no
build_tree() {
    rm -rf "${tmp:?}/t"
    mkdir -p "$tmp/t/usr/share/bashan" "$tmp/t/usr/share/wallpapers" \
             "$tmp/t/usr/share/icons" "$tmp/t/usr/share/plymouth" \
             "$tmp/t/usr/share/sddm" "$tmp/t/usr/share/calamares" \
             "$tmp/t/boot/grub"
    printf 'PUBLIC_RELEASE="%s"\nPLACEHOLDER_ASSETS="%s"\n' "$1" "$2" \
        > "$tmp/t/usr/share/bashan/build-flags"
    cp "$LISTSRC" "$tmp/t/usr/share/bashan/unconfirmed-assets.sha256"
}
run() { BASHAN_PUBLIC_ROOT="$tmp/t" sh "$HOOK" >"$tmp/out" 2>&1; }

echo "the song must stop a public build"
build_tree yes yes
printf 'not really audio\n' > "$tmp/t/usr/share/bashan/boot-song.wav"
if run; then bad "a public build with the song present fails"; else ok "a public build with the song present fails"; fi
want "and says which file" grep -q "must not contain the boot song" "$tmp/out"

# Anywhere, not just the expected path.
build_tree yes yes
mkdir -p "$tmp/t/opt/leftover"
printf 'x\n' > "$tmp/t/opt/leftover/boot-song.mp3"
if run; then bad "even when it is somewhere unexpected"; else ok "even when it is somewhere unexpected"; fi

echo "a private build is not affected"
build_tree no no
printf 'x\n' > "$tmp/t/usr/share/bashan/boot-song.wav"
if run; then ok "private build with the song passes"; else bad "private build with the song passes"; fi

echo "unconfirmed artwork must stop a public build"
build_tree yes no
if run; then bad "real artwork + unconfirmed list fails"; else ok "real artwork + unconfirmed list fails"; fi
want "and says how to proceed" grep -q "PLACEHOLDER_ASSETS=yes" "$tmp/out"

build_tree yes yes
cp theme/wallpapers/bashan-mountain-1920x1080.png \
   "$tmp/t/usr/share/wallpapers/1920x1080.png"
if run; then bad "the mountain wallpaper shipped byte for byte fails"; else ok "the mountain wallpaper shipped byte for byte fails"; fi
want "and names it" grep -q "byte-identical" "$tmp/out"

# The hand came OFF the unconfirmed list on 2026-10-20. Shipping it must now
# be fine, or the public build has no brand mark at all.
build_tree yes yes
cp assets/branding/logo-source.jpg "$tmp/t/usr/share/bashan/logo-source.jpg"
cp branding/plymouth/bashan/logo-256.png "$tmp/t/usr/share/plymouth/logo-256.png"
cp config/bootloaders/grub-pc/splash.png "$tmp/t/boot/grub/splash.png"
want "the hand logo and the boot splashes are allowed through" run
if grep -q "byte-identical" "$tmp/out"; then
    bad "and nothing is reported against them"
else
    ok "and nothing is reported against them"
fi

echo "a clean public build passes"
build_tree yes yes
cp theme/wallpapers/bashan-ridge-1920x1080.png \
   "$tmp/t/usr/share/wallpapers/1920x1080.png"
if run; then ok "ridge art and no song passes"; else bad "ridge art and no song passes"; fi
want "and the list is not left in the image" \
    [ ! -e "$tmp/t/usr/share/bashan/unconfirmed-assets.sha256" ]

echo ""
echo "  $pass passed, $fail failed"
[ "$fail" = 0 ]
