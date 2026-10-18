#!/bin/sh
# TEST ONLY. Stream the Calamares log out of the VM over the serial port.
#
# The previous version copied the log onto a shared FAT disk every 20s. On
# install attempt 4 that produced NOTHING: the guest's writes sat in page
# cache and were lost when the VM was shut down, so the one artefact the
# whole test existed to capture never arrived.
#
# The serial port has no such failure mode. QEMU is started with
# `-serial file:build/vm/serial.log`, so every byte written to /dev/ttyS0
# lands in a host file immediately, survives the guest crashing, being
# killed, or losing power, and can be read while the install is running.
#
# Start this BEFORE launching the installer.
set -u
PORT=/dev/ttyS0
[ -w "$PORT" ] || { echo "E: $PORT not writable; run with sudo" >&2; exit 1; }

say() { printf '%s\n' "$*" > "$PORT"; }

say "=== bashan install log capture started $(date -Is) ==="

# Follow whichever log Calamares actually creates, as soon as it exists.
last_size=0
i=0
while :; do
    i=$((i + 1))
    # Calamares is launched with `sudo -E`, which KEEPS HOME=/home/<liveuser>,
    # so the log is NOT under /root. Missing this captured 2 KB of an install
    # instead of the whole thing.
    for src in /home/*/.cache/calamares/session.log \
               /root/.cache/calamares/session.log \
               "$HOME/.cache/calamares/session.log" \
               /var/log/calamares.log; do
        [ -r "$src" ] || continue
        size=$(wc -c < "$src" 2>/dev/null || echo 0)
        if [ "$size" -gt "$last_size" ]; then
            # Only the new bytes, so the serial log reads as one transcript.
            tail -c "+$((last_size + 1))" "$src" > "$PORT" 2>/dev/null
            last_size=$size
        fi
        break
    done

    # A heartbeat, so a truncated capture can be told from one that never
    # started, and so an OOM kill is visible rather than inferred.
    if [ $((i % 5)) -eq 1 ]; then
        say "--- tick $i $(date -Is) mem: $(free -m | awk 'NR==2{print "avail "$7"MB"}') calamares: $(pgrep -c calamares 2>/dev/null || echo 0) oom: $(dmesg 2>/dev/null | grep -ci 'out of memory\|oom-kill' || echo 0)"
    fi
    sleep 4
done
