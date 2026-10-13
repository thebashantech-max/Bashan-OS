#!/bin/sh
# Bashan OS — prove /etc/xdg/mimeapps.list points at .desktop files that
# will actually exist, and at MIME types trixie actually knows.
#
# A wrong name in mimeapps.list fails SILENTLY: the association is ignored
# and the file opens in whatever app wins by chance. That is exactly the
# kind of defect you only find by using the installed system, so it is
# checked here instead.
#
# Runs INSIDE the build container. Needs the chroot from a previous build
# plus the .debs of anything not yet installed, in /tmp/dl.
set -e
C="${1:-/work/build/work/lb/chroot}"
M="$C/etc/xdg/mimeapps.list"
[ -f "$M" ] || M=/work/hooks/rootfs/etc/xdg/mimeapps.list
[ -f "$M" ] || { echo "E: no mimeapps.list found" >&2; exit 1; }

# Everything that will be on the installed system: desktop files already in
# the chroot, plus desktop files inside the .debs we are about to add.
AVAIL=$(mktemp); MIMES=$(mktemp)
trap 'rm -f "$AVAIL" "$MIMES"' EXIT

find "$C/usr/share/applications/" -maxdepth 1 -name '*.desktop' -printf '%f\n' \
  2>/dev/null > "$AVAIL"
for f in /tmp/dl/*.deb; do
  [ -e "$f" ] || continue
  dpkg -c "$f" 2>/dev/null | sed -n 's|.*/usr/share/applications/\(.*\.desktop\)$|\1|p'
done >> "$AVAIL"
sort -u -o "$AVAIL" "$AVAIL"

grep -oE 'mime-type type="[^"]+"' "$C/usr/share/mime/packages/freedesktop.org.xml" 2>/dev/null \
  | sed 's/.*"\(.*\)"/\1/' | sort -u > "$MIMES"

bad=0
while IFS='=' read -r mime desktop; do
  case "$mime" in ''|'#'*|'['*) continue ;; esac
  grep -qxF "$desktop" "$AVAIL" || { echo "E: no such .desktop: $desktop (for $mime)"; bad=$((bad+1)); }
  grep -qxF "$mime" "$MIMES"    || echo "W: MIME type not in freedesktop.org.xml: $mime"
done < "$M"

n=$(grep -cE '^[a-z]+/[^=]+=' "$M")
if [ "$bad" -gt 0 ]; then
  echo "E: $bad broken association(s) in mimeapps.list" >&2; exit 1
fi
echo "I: all $n default-app associations resolve to real .desktop files"
