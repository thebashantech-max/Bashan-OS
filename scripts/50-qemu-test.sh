#!/usr/bin/env bash
# Bashan OS — QEMU test harness.
#
#   ./scripts/50-qemu-test.sh disks            build the test disks
#   ./scripts/50-qemu-test.sh boot uefi-sb     UEFI with Secure Boot ON
#   ./scripts/50-qemu-test.sh boot bios        legacy BIOS
#   ./scripts/50-qemu-test.sh target           make a blank install disk
#   ./scripts/50-qemu-test.sh boot install     ISO + blank target, to install
#   ./scripts/50-qemu-test.sh boot installed   NO ISO: boot what was installed
#   ./scripts/50-qemu-test.sh boot installed-wiped   as above, NVRAM forgotten
#   ./scripts/50-qemu-test.sh shot NAME        screenshot the running VM
#   ./scripts/50-qemu-test.sh key KEYS         send keystrokes
#   ./scripts/50-qemu-test.sh stop             shut the VM down
#
# Runs headless with a VNC display and a monitor socket, so screenshots can
# be taken without a window being open. Never start this while a build is
# running: the host has under 4 GB free.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR/..
# shellcheck source=config/build.conf
source "$ROOT/config/build.conf"

VM="$ROOT/build/vm"
SHOTS="$ROOT/build/screenshots"
MON="$VM/monitor.sock"
ISO="$ROOT/build/out/$ISO_NAME"
OVMF_CODE_SB="/usr/share/OVMF/OVMF_CODE_4M.ms.fd"
OVMF_VARS_SB="/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
RAM_MB="${BASHAN_VM_RAM:-3584}"
# Read speed of the ISO drive, in bytes/sec. A cheap USB 2.0 stick does
# roughly 25 MB/s; this machine's NVMe does thousands. Everything the live
# session does on first launch - loading Dolphin, Gwenview, KolourPaint -
# reads from a COMPRESSED squashfs, so the real cost is decompression on
# top of a slow bus. Unthrottled QEMU hides that completely, which is why a
# fault seen on a USB stick never appeared in testing.
#   BASHAN_VM_ISO_BPS=26214400 ./scripts/50-qemu-test.sh boot install
ISO_BPS="${BASHAN_VM_ISO_BPS:-0}"
# Reads per second. Bandwidth alone does NOT simulate USB flash: a stick can
# stream 25 MB/s sequentially and still take milliseconds per random read,
# and cheap controllers stall for whole seconds under mixed load. Limiting
# bandwidth only made an earlier test look fine when the real machine was
# not. A cheap stick manages roughly 100-400 random reads/sec; this goes
# harsher to expose anything that assumes storage always answers.
#   BASHAN_VM_ISO_IOPS=80 ./scripts/50-qemu-test.sh boot install
ISO_IOPS="${BASHAN_VM_ISO_IOPS:-0}"
# The VM had NO network device at all until build 17. That is why nothing
# network-driven ever reproduced here: a live session that downloads
# updates, a website that will not load, a name that will not resolve.
# user-mode networking needs no privileges and no host configuration.
iso_throttle() {
  [ "$ISO_BPS" = 0 ] && [ "$ISO_IOPS" = 0 ] && return 0
  [ "$ISO_BPS" != 0 ] && printf ',throttling.bps-read=%s,throttling.bps-read-max=%s' "$ISO_BPS" "$ISO_BPS"
  [ "$ISO_IOPS" != 0 ] && printf ',throttling.iops-read=%s,throttling.iops-read-max=%s' "$ISO_IOPS" "$ISO_IOPS"
  return 0
}
BASHAN_DISK="${BASHAN_DISK:-other-os.img}"

mkdir -p "$VM" "$SHOTS"
die() { echo "E: $*" >&2; exit 1; }

# --- test disks ----------------------------------------------------------
# A fake "Windows is already installed" disk, so the installer's dual-boot
# path can be tested. os-prober identifies Windows by the presence of
# EFI/Microsoft/Boot/bootmgfw.efi on an EFI System Partition, so that is
# what this builds - no root needed, mtools writes the FAT image directly.
cmd_disks() {
  local esp="$VM/esp.img" disk="$VM/other-os.img"
  rm -f "$esp" "$disk"

  echo "I: building a 300 MB EFI System Partition with a Windows loader path"
  truncate -s 300M "$esp"
  mkfs.vfat -F 32 -n "SYSTEM" "$esp" >/dev/null
  mmd -i "$esp" ::/EFI ::/EFI/Microsoft ::/EFI/Microsoft/Boot
  printf 'This is not a real Windows loader. QEMU dual-boot test fixture.\n' \
    > "$VM/bootmgfw.efi"
  mcopy -i "$esp" "$VM/bootmgfw.efi" ::/EFI/Microsoft/Boot/bootmgfw.efi
  rm -f "$VM/bootmgfw.efi"

  echo "I: building a 60 GB disk that looks like it already has Windows"
  truncate -s 60G "$disk"
  parted -s "$disk" mklabel gpt
  parted -s "$disk" mkpart ESP fat32 1MiB 301MiB
  parted -s "$disk" set 1 esp on
  parted -s "$disk" mkpart WinData ntfs 301MiB 100%
  dd if="$esp" of="$disk" bs=1M seek=1 conv=notrunc status=none
  rm -f "$esp"

  echo "I: test disks ready in build/vm/"
  parted -s "$disk" print | sed 's/^/   /'
}

# --- boot ----------------------------------------------------------------
cmd_target() {
  local disk="$VM/target.img"
  rm -f "$disk"
  truncate -s 40G "$disk"
  echo "I: blank 40 GB install target at $disk"
  echo "I: Secure Boot variables reset, so the install writes its own boot entry"
  cp -f "$OVMF_VARS_SB" "$VM/vars-sb.fd"
}

cmd_boot() {
  local mode="${1:-uefi-sb}"
  # "installed-wiped" answers: does this still boot on a machine whose
  # firmware has forgotten its boot entries, after a CMOS reset or a
  # firmware update? Resetting to the pristine Microsoft-keys vars drops
  # every boot variable while leaving Secure Boot ON, so the firmware has
  # no choice but the removable path \EFI\BOOT\BOOTX64.EFI.
  if [ "$mode" = "installed-wiped" ]; then
    cp -f "$OVMF_VARS_SB" "$VM/vars-sb.fd"
    echo "I: NVRAM boot variables wiped, Secure Boot still ON"
    echo "I: only the removable fallback path can boot now"
    mode="installed"
  fi
  # "installed" boots the disk the installer wrote, with NO ISO attached.
  # Until that works, an install has not been proven.
  if [ "$mode" = "installed" ]; then
    [ -f "$VM/target.img" ] || die "no target disk - run: $0 target, then install"
    pgrep -f "qemu-system-x86_64.*bashan-vm" >/dev/null && die "a VM is already running"
    nohup qemu-system-x86_64 \
      -name "bashan-vm" \
      -machine "q35,accel=kvm,smm=on" -cpu host -smp 2 -m "$RAM_MB" \
      -device "virtio-vga" -display none -vnc ":9" \
      -device "qemu-xhci,id=xhci" -device "usb-tablet,bus=xhci.0" -device "virtio-keyboard-pci" \
      -netdev "user,id=net0" -device "virtio-net-pci,netdev=net0" \
      -monitor "unix:$MON,server,nowait" \
        -serial "file:$VM/serial.log" \
      -global "driver=cfi.pflash01,property=secure,value=on" \
      -drive "if=pflash,format=raw,unit=0,readonly=on,file=$OVMF_CODE_SB" \
      -drive "if=pflash,format=raw,unit=1,file=$VM/vars-sb.fd" \
      -drive "file=$VM/target.img,format=raw,if=virtio" \
      -drive "file=$VM/harness.img,format=raw,if=virtio" \
      -rtc "base=localtime" \
      -audiodev "none,id=snd0" -device "intel-hda" -device "hda-duplex,audiodev=snd0" \
      >"$VM/qemu.log" 2>&1 &
    sleep 3
    echo "I: booting the INSTALLED system, Secure Boot ON, no ISO attached"
    echo "I: VM started"
    return 0
  fi

  # "install" is UEFI+Secure Boot pointed at the blank target disk instead
  # of the dual-boot fixture. Resolved BEFORE the case below, because a
  # case tests the word it expanded once and reassigning $mode inside a
  # branch never reaches the later patterns.
  if [ "$mode" = "install" ]; then
    [ -f "$VM/target.img" ] || die "no target disk - run: $0 target"
    BASHAN_DISK="target.img"
    mode="uefi-sb"
  fi

  [ -f "$ISO" ] || die "no ISO at $ISO - run ./build.sh build first"
  pgrep -f "qemu-system-x86_64.*bashan-vm" >/dev/null && die "a VM is already running; ./scripts/50-qemu-test.sh stop"

  local -a args=(
    -name "bashan-vm"
    -machine "q35,accel=kvm" -cpu host -smp 2 -m "$RAM_MB"
    -device "virtio-vga" -display none -vnc ":9"
    -device "qemu-xhci,id=xhci" -device "usb-tablet,bus=xhci.0" -device "virtio-keyboard-pci" \
      -netdev "user,id=net0" -device "virtio-net-pci,netdev=net0"
    # A file sink, not a socket: nothing was ever connected to the socket,
    # and an undrained serial socket can stall the guest. The install log
    # is streamed out through here, where it survives the VM dying.
    -serial "file:$VM/serial.log"
    -monitor "unix:$MON,server,nowait"
    -drive "file=$ISO,media=cdrom,readonly=on$(iso_throttle)"
    -drive "file=$VM/$BASHAN_DISK,format=raw,if=virtio"
    # TEST ONLY: the shared disk the in-guest harness writes its results to.
    # Built by scripts/55-vm-harness.sh; never part of the ISO.
    -drive "file=$VM/harness.img,format=raw,if=virtio"
    -boot d
    -rtc "base=localtime"
    -audiodev "none,id=snd0" -device "intel-hda" -device "hda-duplex,audiodev=snd0"
  )

  case "$mode" in
    uefi-sb)
      [ -f "$OVMF_CODE_SB" ] || die "missing $OVMF_CODE_SB (install ovmf)"
      cp -f "$OVMF_VARS_SB" "$VM/vars-sb.fd"
      args+=(
        -global "driver=cfi.pflash01,property=secure,value=on"
        -drive "if=pflash,format=raw,unit=0,readonly=on,file=$OVMF_CODE_SB"
        -drive "if=pflash,format=raw,unit=1,file=$VM/vars-sb.fd"
        -machine "smm=on"
      )
      echo "I: UEFI with Secure Boot ON (Microsoft keys enrolled)"
      ;;
    bios)
      echo "I: legacy BIOS"
      ;;
    *) die "unknown mode '$mode' (uefi-sb|bios)" ;;
  esac

  echo "I: ${RAM_MB} MB RAM, KVM acceleration, VNC on :9"
  nohup qemu-system-x86_64 "${args[@]}" >"$VM/qemu.log" 2>&1 &
  sleep 3
  pgrep -f "qemu-system-x86_64.*bashan-vm" >/dev/null \
    || { tail -20 "$VM/qemu.log"; die "QEMU failed to start"; }
  echo "I: VM started"
}

monitor() { printf '%s\n' "$1" | socat - "UNIX-CONNECT:$MON" >/dev/null 2>&1 || true; }

cmd_shot() {
  local name="${1:-shot}"
  monitor "screendump $VM/shot.ppm"
  sleep 1
  [ -f "$VM/shot.ppm" ] || die "no screenshot produced"
  convert "$VM/shot.ppm" "$SHOTS/$name.png"
  rm -f "$VM/shot.ppm"
  echo "I: build/screenshots/$name.png"
}

cmd_key()  { monitor "sendkey ${1}"; }
# Stop the VM and PROVE it stopped.
#
# The old version ended with an unconditional `echo "I: VM stopped"`, so it
# reported success even when the process survived. A VM that was wedged
# reading from a throttled disk ignored the monitor "quit", outlived the
# pkill, and then blocked the next boot while this said it was gone. A
# check that cannot fail is worse than no check: the build/QEMU rule relies
# on this answer being true.
cmd_stop() {
  monitor "quit"
  for _ in 1 2 3 4 5; do
    ps -C qemu-system-x86_64 -o pid= >/dev/null 2>&1 || { echo "I: VM stopped"; return 0; }
    sleep 1
  done
  # Still there: ask politely by PID, then insist.
  for sig in TERM KILL; do
    ps -C qemu-system-x86_64 -o pid= 2>/dev/null | while read -r p; do kill "-$sig" "$p" 2>/dev/null || true; done
    for _ in 1 2 3; do
      ps -C qemu-system-x86_64 -o pid= >/dev/null 2>&1 || { echo "I: VM stopped (needed SIG$sig)"; return 0; }
      sleep 1
    done
  done
  echo "E: VM is STILL RUNNING; do not start a build" >&2
  ps -C qemu-system-x86_64 -o pid=,etime= >&2
  return 1
}

case "${1:-}" in
  disks) cmd_disks ;;
  target) cmd_target ;;
  boot)  shift; cmd_boot "$@" ;;
  shot)  shift; cmd_shot "$@" ;;
  key)   shift; cmd_key "$@" ;;
  stop)  cmd_stop ;;
  *)     die "usage: $0 {disks|boot <uefi-sb|bios>|shot NAME|key KEYS|stop}" ;;
esac
