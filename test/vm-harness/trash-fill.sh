#!/bin/sh
# TEST ONLY. Put a real file in the trash, the way the desktop does, so the
# Trash icon has to switch to its full state.
#
# Writes a proper XDG trash entry rather than calling a helper that may not
# be installed: a file in Trash/files plus its .trashinfo in Trash/info is
# exactly what the specification defines, and what Plasma watches.
set -u
T="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
mkdir -p "$T/files" "$T/info"
echo "bashan trash state test" > "$T/files/bashan-test.txt"
cat > "$T/info/bashan-test.txt.trashinfo" <<INFO
[Trash Info]
Path=$HOME/bashan-test.txt
DeletionDate=$(date +%Y-%m-%dT%H:%M:%S)
INFO
echo "trash filled: $(find "$T/files" -type f -printf "%f " 2>/dev/null)"
