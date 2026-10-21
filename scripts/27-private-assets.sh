#!/bin/sh
# Bashan OS — put the local-only artwork back, for private builds.
#
# Three things are deliberately NOT in this repository, because nobody has
# written down the right to redistribute them: the mountain photograph that
# carries the Arabic wordmark, the boot song, and the installer's welcome
# panel. A clone does not have them, and a public build must not.
#
# A private build on the owner's machine should still use the real artwork.
# This copies it from a folder outside the repository, over the generated
# stand-ins the build has already put in place.
#
# It runs on the HOST, after the live-build tree is generated, because the
# build container only has the repository mounted and cannot see that folder.
#
#   ./scripts/27-private-assets.sh <lb-tree> <assets-dir>
#
# Silent about files it does not find: an owner with only some of them gets
# the real ones for those and stand-ins for the rest, which is the point.
set -eu

TREE="${1:?usage: $0 <lb-tree> <assets-dir>}"
SRC="${2:?usage: $0 <lb-tree> <assets-dir>}"
INC="$TREE/config/includes.chroot"

[ -d "$INC" ] || { echo "E: $INC is not there; run this after the config stage" >&2; exit 1; }
[ -d "$SRC" ] || { echo "I: no private assets at $SRC; keeping the generated art"; exit 0; }

n=0
put() {  # <source, relative to SRC> <destination, relative to INC>
    [ -f "$SRC/$1" ] || return 0
    mkdir -p "$INC/$(dirname "$2")"
    cp -a "$SRC/$1" "$INC/$2"
    n=$((n + 1))
}

W=usr/share/wallpapers/BashanMountain/contents/images
put theme/wallpapers/bashan-mountain-1920x1080.png        "$W/1920x1080.png"
put theme/wallpapers/bashan-mountain-16x9-native.png      "$W/1280x720.png"
put theme/wallpapers/bashan-mountain-original-1280x1024.png "$W/1280x1024.png"

put installer/branding/bashan/welcome.png \
    usr/share/calamares/branding/bashan/welcome.png

# The song only goes in when it was asked for. INCLUDE_BOOT_SONG=no must
# still mean no audio, even on a machine that has the file.
if [ "${INCLUDE_BOOT_SONG:-no}" = "yes" ]; then
    put branding/boot-song/boot-song.wav usr/share/bashan/boot-song.wav
fi

if [ "$n" -gt 0 ]; then
    echo "I: private assets: $n real file(s) restored from $SRC"
else
    echo "I: private assets: none found in $SRC; keeping the generated art"
fi
