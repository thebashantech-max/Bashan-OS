#!/bin/bash
# Drive a full Calamares install in the VM. ISO picked by ISO_NAME, tag by TAG.
# Lives in the repo now: /tmp gets cleaned mid-session and took this with it.
set -u
cd ~/Bashan-OS-1.0
S="$PWD/test/vm-drive"
Q=./scripts/50-qemu-test.sh
MON="$PWD/build/vm/monitor.sock"
T="${TAG:-X}"
$Q target >/dev/null 2>&1
$Q boot install 2>&1 | grep -E "VM started"
sleep 70
$Q key alt-f4 >/dev/null; sleep 2
$Q key alt-f2 >/dev/null; sleep 3
python3 "$S/type.py" "$MON" "konsole"; sleep 2
$Q key ret >/dev/null; sleep 13
# The QEMU pointer does not work, so the Partitions radio cannot be clicked.
# This preselects erase in the RUNNING VM only; the ISO is untouched.
python3 "$S/type.py" "$MON" "sudo sed -i 11s/none/erase/ /etc/calamares/modules/partition.conf"
sleep 1; $Q key ret >/dev/null; sleep 4
$Q key alt-f4 >/dev/null; sleep 3
$Q key alt-f2 >/dev/null; sleep 3
python3 "$S/type.py" "$MON" "install"; sleep 2
$Q key ret >/dev/null; sleep 28
$Q shot "${T}-inst-welcome" >/dev/null
$Q key alt-n >/dev/null; sleep 7
$Q key alt-n >/dev/null; sleep 8
$Q key alt-n >/dev/null; sleep 14
$Q shot "${T}-inst-partitions" >/dev/null
$Q key alt-n >/dev/null; sleep 9
python3 "$S/type.py" "$MON" "tester"; sleep 1
for _ in 1 2 3; do $Q key tab >/dev/null; sleep 0.7; done
python3 "$S/type.py" "$MON" "bashan1234"; sleep 1
$Q key tab >/dev/null; sleep 0.7
python3 "$S/type.py" "$MON" "bashan1234"; sleep 2
$Q key alt-n >/dev/null; sleep 9
$Q shot "${T}-inst-summary" >/dev/null
$Q key alt-i >/dev/null; sleep 6
$Q key ret >/dev/null
sleep 420
$Q shot "${T}-inst-done" >/dev/null
$Q stop 2>&1 | tail -1
