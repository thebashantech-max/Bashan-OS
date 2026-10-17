#!/bin/sh
# TEST ONLY. Empty the trash again, so the icon has to switch back.
set -u
T="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
rm -f "$T/files/"* "$T/info/"* 2>/dev/null
echo "trash emptied: [$(find "$T/files" -type f -printf '%f ' 2>/dev/null)]"
