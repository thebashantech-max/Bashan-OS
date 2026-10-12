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
  --uefi-secure-boot enable \
  --debian-installer none \
  --firmware-binary true \
  --firmware-chroot true \
  --linux-packages linux-image \
  --memtest none \
  --apt-indices false \
  --chroot-squashfs-compression-type zstd \
  --chroot-squashfs-compression-level 15 \
  --zsync false \
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

# Overlay sources copied verbatim into the image:
#   hooks/rootfs  - system tuning and defaults
#   apps/rootfs    - the Bashan app wrapper, Chrome placeholder, icons
#   theme/rootfs   - Konsole, cursors, fastfetch, Plasma desktop theme
#   branding/rootfs - os-release inputs, grub/sddm config, boot-sound service
echo "I: rootfs overlays"
for src in "$ROOT/hooks/rootfs" "$ROOT/apps/rootfs" \
           "$ROOT/theme/rootfs" "$ROOT/branding/rootfs"; do
  [ -d "$src" ] || continue
  cp -a "$src/." config/includes.chroot/
done

# --- theme -------------------------------------------------------------
# Assembled rather than copied, because the trash icon variant is a choice.
echo "I: theme (trash variant ${TRASH_VARIANT:-B})"
inc="config/includes.chroot/usr/share"
mkdir -p "$inc/wallpapers/Bashan/contents/images" "$inc/color-schemes" \
         "$inc/plasma/look-and-feel" "$inc/icons"

cp -a "$ROOT"/theme/wallpapers/*.png "$inc/wallpapers/Bashan/contents/images/"
# Plasma looks for the wallpaper by its pixel dimensions.
cp -a "$ROOT/theme/wallpapers/bashan-ridge-3840x2160.png" \
      "$inc/wallpapers/Bashan/contents/images/3840x2160.png"
cp -a "$ROOT/theme/wallpapers/bashan-ridge-1920x1080.png" \
      "$inc/wallpapers/Bashan/contents/images/1920x1080.png"
cp -a "$ROOT/theme/color-schemes/Bashan.colors" "$inc/color-schemes/"
cp -a "$ROOT/theme/look-and-feel/com.bashan.desktop" "$inc/plasma/look-and-feel/"

# --- boot-chain branding ------------------------------------------------
echo "I: boot branding"
mkdir -p "$inc/plymouth/themes" config/includes.chroot/boot/grub/themes \
         "$inc/sddm/themes" "$inc/bashan"
cp -a "$ROOT/branding/plymouth/bashan" "$inc/plymouth/themes/"
cp -a "$ROOT/branding/grub/bashan" config/includes.chroot/boot/grub/themes/
cp -a "$ROOT/branding/sddm/bashan" "$inc/sddm/themes/"

# os-release and friends, generated so they can never drift from build.conf.
mkdir -p config/includes.chroot/usr/lib config/includes.chroot/etc
cat > config/includes.chroot/usr/lib/os-release <<EOF
PRETTY_NAME="$OS_NAME $OS_VERSION"
NAME="$OS_NAME"
VERSION_ID="$OS_VERSION"
VERSION="$OS_VERSION ($OS_CODENAME)"
VERSION_CODENAME=$OS_ID
ID=$OS_ID
ID_LIKE=debian
HOME_URL="$OS_HOME_URL"
SUPPORT_URL="$OS_HOME_URL"
BUG_REPORT_URL="$OS_HOME_URL"
PRIVACY_POLICY_URL="$OS_HOME_URL"
LOGO=bashan-launcher
ANSI_COLOR="0;36"
VENDOR_NAME="$OS_PUBLISHER"
EOF
# Debian ships /etc/os-release as a symlink into /usr/lib; keep that shape.
ln -sf ../usr/lib/os-release config/includes.chroot/etc/os-release

cat > config/includes.chroot/etc/issue <<EOF
$OS_NAME $OS_VERSION \\n \\l

EOF
cat > config/includes.chroot/etc/issue.net <<EOF
$OS_NAME $OS_VERSION
EOF
cat > config/includes.chroot/etc/motd <<EOF

  $OS_NAME $OS_VERSION — $OS_PUBLISHER
  $OS_HOME_URL

EOF

# --- translation review status -----------------------------------------
if [ -r "$ROOT/i18n/UNREVIEWED" ]; then
  unreviewed=$(cat "$ROOT/i18n/UNREVIEWED")
  if [ -n "$unreviewed" ]; then
    echo "W: ----------------------------------------------------------------"
    echo "W:  TRANSLATIONS NOT REVIEWED BY A NATIVE SPEAKER:"
    echo "W:    $unreviewed"
    echo "W:  Kurmanji (ku), Sorani (ckb) and Syriac (syr) are machine"
    echo "W:  translations of LOW or VERY LOW confidence and should not be"
    echo "W:  shown to users before review. i18n/REVIEW.csv is the file to"
    echo "W:  hand a native speaker."
    echo "W: ----------------------------------------------------------------"
  fi
fi

# --- boot song ----------------------------------------------------------
if [ "${INCLUDE_BOOT_SONG:-no}" = "yes" ]; then
  if [ "${PUBLIC_RELEASE:-no}" = "yes" ]; then
    echo "E: INCLUDE_BOOT_SONG=yes with PUBLIC_RELEASE=yes." >&2
    echo "E: The boot song's rights are unconfirmed. It must not ship in a" >&2
    echo "E: public release. Set INCLUDE_BOOT_SONG=no, or confirm the rights" >&2
    echo "E: and remove this guard deliberately." >&2
    exit 1
  fi
  cp -a "$ROOT/branding/boot-song/boot-song.wav" "$inc/bashan/"
  echo "W: ================================================================"
  echo "W:  BOOT SONG INCLUDED - PRIVATE TEST BUILD ONLY"
  echo "W:  Rights for this audio are not confirmed. Do not distribute"
  echo "W:  this ISO publicly. Set INCLUDE_BOOT_SONG=no in config/build.conf"
  echo "W:  to build without it."
  echo "W: ================================================================"
else
  echo "I: boot song omitted (INCLUDE_BOOT_SONG=no); splash still holds"
fi

# --- Calamares installer -----------------------------------------------
# Lives on the live ISO only: the packages module removes Calamares during
# install, so none of this reaches the user's disk.
echo "I: calamares installer"
mkdir -p config/includes.chroot/etc/calamares/modules "$inc/calamares/branding"
cp -a "$ROOT/installer/settings.conf" config/includes.chroot/etc/calamares/
cp -a "$ROOT"/installer/modules/*.conf config/includes.chroot/etc/calamares/modules/
cp -a "$ROOT/installer/branding/bashan" "$inc/calamares/branding/"

variant="$ROOT/theme/icons/Bashan-${TRASH_VARIANT:-B}"
if [ ! -d "$variant" ]; then
  echo "E: unknown TRASH_VARIANT '${TRASH_VARIANT:-}' (expected A or B)" >&2
  exit 1
fi
rm -rf "$inc/icons/Bashan"
cp -a "$variant" "$inc/icons/Bashan"
find config/includes.chroot -type f | sed 's|^config/includes.chroot|  /|' | sort

echo "I: live-build tree ready"
