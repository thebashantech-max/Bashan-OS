# Hardware compatibility — an honest statement

**Bashan OS 1.0 is not a universal operating system.** It is a Debian 13
build tested in a virtual machine and, when the owner reports back, on
**one** real laptop. Everything below says what has actually been tried and
what has not.

Last updated: 2026-10-20.

## What has been tested

| Where | What |
|---|---|
| **One real ASUS ROG laptop**, live USB, UEFI | boots, reaches the desktop, desktop usable |
| QEMU, UEFI with **Secure Boot on** | boots to desktop |
| QEMU, legacy BIOS | boots to desktop |
| QEMU | installer runs to completion, safety rules behave |
| QEMU | installed system boots, logs in, locks, shuts down |

**That is the whole list.** One real machine has booted the live session; no
real machine has ever had Bashan OS installed to its disk. Everything else
was a virtual machine with virtual hardware, which always works — it proves
the software, not the driver support.

Defects found on that laptop were fixed in later builds and **have not been
re-tested on it**. They were verified in a virtual machine only.

## What has NOT been tested

- **Installing to a real disk.** Not once, on any machine.
- Wi-Fi, Bluetooth, sound, touchpad, brightness, sleep and wake on real
  hardware.
- Any machine other than the one laptop described in
  `docs/HARDWARE-TEST-DAD-LAPTOP.md`.
- Printers, scanners, external monitors, docking stations, fingerprint
  readers, SD card readers.
- Upgrading from any earlier version.

If you are reading this deciding whether to run Bashan OS on a machine you
depend on: **do not, yet.** Run the live USB first and work through
`docs/LAPTOP-TEST.md`.

## Known gaps

### 1. NVIDIA graphics

The NVIDIA driver is **not in the ISO** — it is non-free and most machines
do not have an NVIDIA card. A one-click installer is in the menu as
**NVIDIA Graphics Driver**, which fetches it from Debian.

With **Secure Boot on**, the driver is built on your own machine and
therefore unsigned, and Secure Boot will refuse to load it. The installer
handles this by creating a key and queueing it for enrolment, and explains
in three numbered steps what the blue **MOK Manager** screen is and what to
click. **This has never been tested on real hardware.**

Hybrid graphics (a built-in chip plus an NVIDIA card, which is what gaming
laptops have) are handled conservatively: the built-in chip keeps driving
the screen, and `bashan-run-on-nvidia <program>` sends one program to the
NVIDIA card. **No `xorg.conf` is written** — forcing the NVIDIA card to
drive a laptop display is the classic route to a black screen.

### 2. Older Broadcom Wi-Fi — a real removal

`firmware-b43-installer` was **removed**. It covers Broadcom chips roughly
BCM4306 through BCM4322, found in laptops around 2006–2012.

It was removed because it contains **no firmware**: it downloads it from
Broadcom at install time, which fails on an offline install from USB — the
exact scenario this OS is built for.

**If your laptop has one of those chips, Bashan OS will have no Wi-Fi out of
the box.** Workarounds: plug in ethernet once after installing, or use a USB
Wi-Fi adapter (Realtek and Atheros ones work with what is shipped).

Newer Broadcom (`brcmfmac`, `brcmsmac`) is fine — `firmware-brcm80211` ships.

### 3. Brand-new Wi-Fi and Bluetooth chips

The firmware comes from Debian 13, frozen in 2025. A laptop bought after
that may have a chip whose firmware is newer than anything shipped. The
symptom is no networks appearing at all.

### 4. Trimmed firmware

283.2 MB of firmware was removed: datacenter network cards, Fibre Channel
adapters, telephony boards, TV tuners. **Everything a laptop needs was
kept** — Intel, Atheros, Realtek, MediaTek, Broadcom and Marvell Wi-Fi and
Bluetooth, AMD/Intel/NVIDIA graphics, SOF/Cirrus/Intel audio, both CPU
microcodes — and the build **fails** if any of those goes missing. Full list
in `config/archives/bashan-firmware-trim.pref.chroot`.

If you are installing this on a server, it is the wrong operating system.

### 5. ASUS laptops specifically

Measured against trixie:

**Works, through drivers built into the Debian kernel:**

| Kernel module | What it gives |
|---|---|
| `asus-nb-wmi`, `asus-wmi` | function keys, keyboard backlight, screen brightness |
| `hid-asus` | the keyboard and touchpad themselves |
| `asus-ec-sensors`, `asus_wmi_sensors` | fan speed and temperature readings |
| `power-profiles-daemon` | the power modes in Plasma's battery menu |

**Does not work — the tools do not exist in Debian 13:**

| Missing | Consequence |
|---|---|
| `asusctl` | **no RGB keyboard lighting control**, no per-key colours, no custom fan curves |
| `supergfxctl` | **no graphics-mode switching UI** (Integrated / Hybrid / dGPU). The mode set in the ASUS firmware is what you get. |
| `rog-control-center` | no ASUS Armoury-Crate-style control panel |

These are real Debian gaps, not Bashan OS decisions. They come from a
third-party repository upstream, which we deliberately do not add: it would
mean an extra apt source outside Debian's security process. **On an ASUS
gaming laptop, expect the keys and brightness to work and the gaming
extras not to.**

Fan behaviour falls back to whatever the laptop's own firmware does, which
on most ASUS machines is adequate but louder than Armoury Crate's quiet
profile.

### 6. The desktop Trash has no fixed position

The Trash is a Plasma widget, and **Plasma decides where it appears** - it
is not in a corner, and it is not mirrored for right-to-left languages.

This was specified as bottom-right for left-to-right languages and
bottom-left for right-to-left ones. Plasma 6 provides no way to set a
desktop widget's position: Folder View has no position system, the Desktop
containment ignores assigned geometry, and the scripting API refuses both.
All of it was tested in QEMU; the detail is in `docs/DESIGN.md`.

**Drag the Trash where you want it once and Plasma will remember.**

The trade was deliberate. A static desktop icon can sit in a corner but
always draws the EMPTY bin, even when the trash is full. The widget shows
the right artwork in both states and switches by itself.

### 7. Translations

Thirteen languages ship. **None has been checked by a native speaker.**
Kurmanji and Sorani are rated LOW confidence, Syriac VERY LOW. The system
says so on screen when you are using one of them.

### 8. "Install alongside" is unproven

Dual-boot installation **has never been successfully tested.** The Stage 9
test could not exercise it because the test disk had no genuinely bootable
operating system on it. Do not use a machine you care about to find out.

## Reporting what you find

`docs/LAPTOP-TEST.md` is a 12-point checklist. Results go into
`docs/HARDWARE-TEST-DAD-LAPTOP.md` and get summarised here.

**A "fail" is more useful than a "pass".** The gaps above exist because they
were looked for, not because the build is weak.
