# Collecting hardware details from Dad's laptop

**Everything here only READS.** Nothing writes to a disk, changes a setting,
installs anything or touches his files. The only thing created is one text
file in his home folder, which you can delete afterwards.

**Run these on HIS laptop**, in a terminal, while it is running the old
prototype.

## Opening a terminal

Press **Ctrl + Alt + T**. If that does nothing, open the menu and type
`Terminal`, then open it.

## Step 1 — the main collection (no password needed)

Select the whole block below, copy it, paste it into the terminal, press
Enter. It takes a few seconds.

```
{
echo "=== BASHAN HARDWARE REPORT ==="; date; echo
echo "=== MACHINE ==="
for f in sys_vendor product_name product_version product_family board_name bios_vendor bios_version bios_date chassis_type; do
  printf '%-18s %s\n' "$f" "$(cat /sys/class/dmi/id/$f 2>/dev/null)"
done
echo; echo "=== OS CURRENTLY INSTALLED ==="; cat /etc/os-release; uname -a
echo; echo "=== CPU ==="; lscpu | grep -Ei 'model name|^architecture|^cpu\(s\)|vendor|core|thread|mhz|flags.*(svm|vmx)' | head -12
echo; echo "=== MEMORY ==="; free -h
echo; echo "=== STORAGE (ROTA 1 = spinning disk, 0 = SSD) ==="
lsblk -o NAME,SIZE,TYPE,ROTA,FSTYPE,MOUNTPOINT,MODEL
echo; echo "=== DISK FREE ==="; df -h / /home 2>/dev/null
echo; echo "=== PCI DEVICES WITH DRIVERS (the important one) ==="; lspci -nnk
echo; echo "=== USB DEVICES ==="; lsusb
echo; echo "=== NETWORK INTERFACES ==="; ip -br link
echo; echo "=== WIRELESS ==="; rfkill list 2>/dev/null; iw dev 2>/dev/null
echo; echo "=== LOADED KERNEL MODULES ==="; lsmod | sort
echo; echo "=== AUDIO CARDS ==="; cat /proc/asound/cards 2>/dev/null; aplay -l 2>/dev/null
echo; echo "=== AUDIO CODEC ==="; grep -h -E 'Codec|Vendor Id|Subsystem Id' /proc/asound/card*/codec* 2>/dev/null | head -20
echo; echo "=== SCREEN ==="; xrandr 2>/dev/null | head -20
echo; echo "=== SECURE BOOT ==="; mokutil --sb-state 2>/dev/null || echo "mokutil not installed"
echo; echo "=== FIRMWARE TYPE ==="; [ -d /sys/firmware/efi ] && echo "UEFI" || echo "Legacy BIOS"
echo; echo "=== BATTERY ==="
for b in /sys/class/power_supply/BAT*; do
  [ -e "$b" ] || continue; echo "-- $b"
  for f in manufacturer model_name technology energy_full energy_full_design charge_full charge_full_design capacity status cycle_count; do
    printf '   %-20s %s\n' "$f" "$(cat $b/$f 2>/dev/null)"
  done
done
echo; echo "=== THERMAL ==="
for z in /sys/class/thermal/thermal_zone*; do
  [ -e "$z" ] || continue
  printf '%-28s %s  %s\n' "$z" "$(cat $z/type 2>/dev/null)" "$(cat $z/temp 2>/dev/null)"
done
sensors 2>/dev/null | head -30
echo; echo "=== END OF STEP 1 ==="
} > ~/bashan-hardware-report.txt 2>&1; echo "Saved. Now do Step 2."
```

## Step 2 — kernel messages (asks for his password once)

This one needs a password because the kernel log is protected. It still only
reads.

```
{
echo; echo "=== KERNEL ERRORS ==="
sudo dmesg --level=err,warn 2>/dev/null | tail -60
echo; echo "=== FIRMWARE LOADING ==="
sudo dmesg 2>/dev/null | grep -iE 'firmware|microcode' | tail -40
echo; echo "=== FIRMWARE FAILURES (this is the one that matters) ==="
sudo dmesg 2>/dev/null | grep -iE 'firmware.*(fail|not found|missing|direct loading|timeout)' | tail -30
echo; echo "=== WIFI / BLUETOOTH / GPU / AUDIO MESSAGES ==="
sudo dmesg 2>/dev/null | grep -iE 'iwlwifi|ath[0-9]|rtw|rtl|brcm|mt79|mwifiex|bluetooth|btusb|amdgpu|radeon|i915|nouveau|nvidia|snd_hda|sof-audio|cirrus' | tail -50
echo; echo "=== SUSPEND / RESUME ==="
sudo journalctl -b -g 'suspend\|resume\|PM:' --no-pager 2>/dev/null | tail -30
echo; echo "=== END OF STEP 2 ==="
} >> ~/bashan-hardware-report.txt 2>&1; echo "Done. File is ~/bashan-hardware-report.txt"
```

## Step 3 — check it is readable and copy it to the USB

```
wc -l ~/bashan-hardware-report.txt && head -20 ~/bashan-hardware-report.txt
```

Then plug in a USB stick, open the **Files** manager, and drag
`bashan-hardware-report.txt` from his Home folder onto the USB stick. Eject
it properly before pulling it out.

Or, from the terminal, with the stick plugged in:

```
cp ~/bashan-hardware-report.txt /media/$USER/*/ 2>/dev/null && echo "Copied to the USB stick" || echo "Copy it with the Files manager instead"
```

## What is in the file

Hardware model numbers, chip names, kernel driver names, battery health,
temperatures and kernel messages.

**What is NOT in it:** no passwords, no Wi-Fi keys, no file names, no
documents, no browsing history, no disk serial numbers. It does include the
laptop's network interface hardware addresses and its model and BIOS
details, which identify the machine but not the person.

Read it first if you want to; it is plain text.

## If a command is not found

- `mokutil not found` — Secure Boot state unknown, not a problem; check it
  in the firmware setup screen instead.
- `sensors not found` — temperatures come from the thermal zones above
  instead.
- `iw not found` — skip it, `lspci -nnk` already identifies the Wi-Fi chip.

None of these stops the rest from working.
