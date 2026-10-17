#!/bin/sh
# TEST ONLY. Copy the Calamares log to the shared disk every 20 seconds, so
# it survives the installer crashing.
#
# Stage 1 failed and took its own log with it: the log lived in the live
# session's RAM filesystem, the installer window vanished, and there was
# nothing left to read. Copying after the failure is too late by
# definition.
#
# Start this BEFORE launching the installer. Ctrl-C or kill it afterwards.
set -u
DEST=/mnt/bashan-test
mkdir -p "$DEST" 2>/dev/null || true

i=0
while :; do
    i=$((i + 1))
    for src in /root/.cache/calamares/session.log \
               "$HOME/.cache/calamares/session.log" \
               /var/log/calamares.log; do
        if sudo test -r "$src" 2>/dev/null; then
            sudo cp -f "$src" "$DEST/calamares.log" 2>/dev/null
        fi
    done
    # A heartbeat, so a truncated capture can be told apart from one that
    # never started.
    {
        printf 'tick %s  %s\n' "$i" "$(date -Is)"
        printf 'mem: %s\n' "$(free -m | awk 'NR==2{print "total "$2" used "$3" avail "$7}')"
        printf 'calamares running: %s\n' "$(pgrep -c calamares 2>/dev/null || echo 0)"
        printf 'dmesg oom: %s\n' "$(sudo dmesg 2>/dev/null | grep -ci 'out of memory\|oom-kill' || echo 0)"
    } > "$DEST/watch-status.txt" 2>/dev/null
    sync 2>/dev/null
    sleep 20
done
