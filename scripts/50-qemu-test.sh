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
      -device "virtio-tablet-pci" -device "virtio-keyboard-pci" \
      -monitor "unix:$MON,server,nowait" \
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
    -device "virtio-tablet-pci" -device "virtio-keyboard-pci"
    -serial "unix:$VM/serial.sock,server,nowait"
    -monitor "unix:$MON,server,nowait"
    -drive "file=$ISO,media=cdrom,readonly=on"
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
cmd_stop() { monitor "quit"; sleep 2; pkill -f "qemu-system-x86_64.*bashan-vm" 2>/dev/null || true; echo "I: VM stopped"; }

case "${1:-}" in
  disks) cmd_disks ;;
  target) cmd_target ;;
  boot)  shift; cmd_boot "$@" ;;
  shot)  shift; cmd_shot "$@" ;;
  key)   shift; cmd_key "$@" ;;
  stop)  cmd_stop ;;
  *)     die "usage: $0 {disks|boot <uefi-sb|bios>|shot NAME|key KEYS|stop}" ;;
esac
