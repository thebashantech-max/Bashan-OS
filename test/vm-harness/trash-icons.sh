#!/bin/sh
# TEST ONLY. Report which icon FILES the running desktop would use for the
# trash, with checksums, so the host can compare them against the approved
# artwork instead of judging by eye.
set -u
OUT=/mnt/bashan-test/trash-icons.txt
: > "$OUT"
theme=$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null)
echo "active icon theme: ${theme:-unknown}" >> "$OUT"
for t in "$theme" Bashan Bashan-Light; do
    [ -n "$t" ] || continue
    for s in 48 64 128 256; do
        for n in user-trash user-trash-full; do
            f="/usr/share/icons/$t/${s}x${s}/places/$n.png"
            if [ -f "$f" ]; then
                printf '%s  %s/%s/%s\n' "$(sha256sum "$f" | cut -d" " -f1)" "$t" "$s" "$n" >> "$OUT"
            fi
        done
    done
done
echo "wrote $OUT"
