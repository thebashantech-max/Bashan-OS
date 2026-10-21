# Bashan OS 1.0 — Public Preview

A desktop Linux built from Debian 13 (trixie) with KDE Plasma 6, published by
Bashan Tech LLC.

> **Public Preview. Do not put this on a computer you depend on.**
> One real laptop has ever booted it, from a USB stick, and it has never been
> installed to a real disk by anyone. Everything else below is measured in a
> virtual machine. Read [What has actually been tested](#what-has-actually-been-tested)
> before you download anything.

---

## What it is

A general-purpose desktop: web browser, office suite, mail, photos, music and
video, plus programming and teaching tools. It is assembled from Debian's own
archive — the software is the same software Debian ships, configured and
branded differently. It installs alongside or instead of an existing system
using the Calamares installer.

It is **not** a Debian product and is not endorsed by Debian, KDE, or Brave.
See [NOTICES.md](NOTICES.md).

---

## Download

**This is a Public Preview.** It has been tested on one laptop and in virtual
machines, and has never been installed to a real disk. Do not put it on a
computer you depend on, and back up your files first.

| | |
|---|---|
| Download | <https://archive.org/details/bashan-os-1-0-public-preview> |
| SHA256 | `2f7a2c5224762176ee152b4c966d358086e1241924a9274fbab55bdf13d67727` |
| Size | 3,339,059,200 bytes (about 3.1 GB) |

Check the download before you write it to anything:

```bash
sha256sum Bashan-OS-1.0-amd64-public.hybrid.iso
```

If a single character of the result differs from the checksum above, delete
the file and fetch it again.

[docs/DOWNLOAD.md](docs/DOWNLOAD.md) has the full instructions — what you
need, how to verify on Windows and macOS, how to write the USB stick with
Balena Etcher or `dd`, and how to boot it.

---

## What has actually been tested

### On real hardware — one machine, live USB only

A single ASUS ROG laptop: Intel Core i7-6700HQ, 16 GB RAM, Intel integrated
graphics plus an NVIDIA GTX 960M, a spinning HGST hard disk, UEFI firmware.

| Tried | Result |
|---|---|
| Boot from USB, UEFI | works |
| Reaching the desktop | works |
| Using the desktop | works |

Defects were found on that machine and fixed in later builds — screen dimming
after a few seconds, a KDE Wallet password popup, the wrong timezone, an
unbranded login screen, "installing updates" on shutdown, the wallpaper
resetting, Arabic keyboard switching, and the boot sound not playing.
**Those fixes have not been re-tested on that laptop.** They were verified in
a virtual machine only.

### In a virtual machine only (QEMU/KVM)

| Tried | Result |
|---|---|
| UEFI boot with Secure Boot ON | works |
| Legacy BIOS boot | works |
| Full install to a blank disk | works |
| Booting the installed system, no ISO | works |
| Booting after the firmware forgets its boot entry | works |
| Password required at login | works |
| Lock screen, including Shut Down and Restart by keyboard | works |
| Timezone, keyboard layout and locale on the installed system | works |
| 26 locales, including right-to-left and Chinese | render correctly |
| Add-on installer with no network | reports it clearly |
| Suspend and wake in the live session | no password prompt (see note) |

The suspend result was read from inside the running system, not from the
screen: QEMU's virtual graphics card does not bring the display back after
sleep, so **screen behaviour on wake is untested**.

One failure is open: on one boot of the installed system **the login screen
did not appear and the screen stayed black.** The system itself was running —
a text console worked. The cause is in the log: SDDM's Wayland greeter failed
(`HELPER_DISPLAYSERVER_ERROR`) and only recovered by falling back to X11 when
restarted. It did not happen on the other boots. It may be the virtual
graphics card. **It has not been ruled out on real hardware.**

### Never tested anywhere

- Installing to a real disk, on any machine.
- Wi-Fi, Bluetooth, sound through real speakers, the touchpad, screen
  brightness, the battery, the lid switch, the webcam, the SD card reader.
- Suspend and wake on real hardware.
- The NVIDIA driver installer and its Secure Boot key enrolment.
- Printers, scanners, external monitors, docking stations, fingerprint
  readers.
- Any machine other than the one laptop above.
- Upgrading from any earlier version. There is no upgrade path.
- Reading from a slow USB stick. A deliberate test at 80 reads per second
  never finished booting in six minutes; this is **not** explained, and a
  cheap stick may behave the same way.

`docs/COMPATIBILITY.md` carries the longer version of this list.

---

## Known limitations

Read this before you download. None of it is hidden in a tracker.

**Some artwork is a stand-in.** The rights to three pieces are not settled,
so this release ships plain generated substitutes:

- the desktop wallpaper is a generated mountain ridge, not the photograph
  that carries the Arabic wordmark **باشان**;
- the Trash icons are Breeze's, not Bashan's glass artwork;
- the installer's first page shows a plain panel, not the multilingual
  welcome panel.

The hand mark — the "OK hand" — *is* the real artwork and is Bashan Tech
LLC's, all rights reserved.

**The boot song has been removed.** Earlier builds played a short piece of
music at startup and on the welcome screen. Its rights are not settled, so it
is not in this ISO: startup is silent and there is no Mute button because
there is nothing to mute.

**Three translations have never been checked by a speaker.** Kurmanji,
Sorani and Syriac are machine translations of low confidence, and that
includes **the installer's warning that a disk is about to be erased**. If
you read one of those languages, do not rely on the warning text — read the
English, or check the disk page carefully before pressing Next. The other ten
languages are higher confidence but are also unreviewed.

**Most testing was in a virtual machine.** One real laptop has booted the USB
stick. **No machine has ever had Bashan OS installed to a real disk.** Wi-Fi,
Bluetooth, sound through real speakers, the touchpad, screen brightness, the
battery, the lid switch, the webcam, suspend and wake, printers and external
monitors are all untested on real hardware. So is the NVIDIA driver
installer.

**There is no Bashan update channel yet.** Debian's own updates work
normally: security updates install automatically in the background, and you
can install the rest yourself through **Discover**. But fixes to Bashan's
*own* parts — the branding, the welcome app, the login configuration —
cannot reach a machine that is already installed. Today the only way to get
them is to reinstall from a newer ISO. An apt repository to fix this is
designed but not built; see `docs/APT-REPOSITORY-DESIGN.md`.

**You will not be told when updates exist.** The desktop's update notifier is
deliberately switched off, so nothing nags you. Security updates still
install by themselves; anything else waits until you open Discover.

## System requirements

| | |
|---|---|
| Processor | 64-bit x86 (`x86_64` / `amd64`). ARM is not supported. |
| Firmware | UEFI, with or without Secure Boot. Legacy BIOS also boots. |
| Memory | 4 GB to run the live session comfortably. Tested at 3.5 GB. |
| Disk, to install | 20 GB minimum, enforced by the installer. |
| USB stick | 4 GB or larger. |
| Graphics | Anything with a working open-source driver. NVIDIA cards fall back to the built-in chip unless you run the driver installer. |

---

## Verifying the download

Always check the ISO before writing it. On Linux or macOS:

```bash
sha256sum Bashan-OS-1.0-amd64.hybrid.iso
```

Compare the result to the published checksum, character for character. If it
differs by even one character, **do not use the file** — it is damaged or it
is not the file we published.

---

## Writing the USB stick

This erases the stick completely. Get the device name wrong and you erase the
wrong disk, so check twice.

List your disks and find the stick by size and model:

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,RM,MOUNTPOINTS
```

The stick is the one with `TRAN=usb` and `RM=1`. Unmount any of its partitions
that are mounted, then write the image — replace `/dev/sdX` with the whole
device, not a partition:

```bash
sudo dd if=Bashan-OS-1.0-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Verify the stick afterwards by reading back exactly as many bytes as the ISO
contains and hashing them:

```bash
sudo head -c "$(stat -c %s Bashan-OS-1.0-amd64.hybrid.iso)" /dev/sdX | sha256sum
```

That must print the same checksum as the ISO.

---

## Building from source

The build runs Debian's `live-build` inside a rootless podman container, so
the host does not need to be Debian.

Host packages: `podman`, `mtools`, `shellcheck`, `dosfstools`, plus
`qemu-system-x86` and `ovmf` if you want to test the result.

```bash
./build.sh container   # create the build container
./build.sh config      # generate the live-build tree
./build.sh build       # build the ISO (about 10 minutes, ~10 GB of disk)
./build.sh test        # run the checks: shellcheck, self-tests, theme checks
```

The ISO lands in `build/out/`. `./build.sh config` wipes the chroot, so a
rebuild after it is a full rebuild.

`docs/BUILD.md` explains the stages and why the build is split into them.

### Public and private builds

`config/build.conf` has a `PUBLIC_RELEASE` switch. A public build refuses to
include anything whose redistribution rights are not settled — see
[LICENSE](LICENSE) and Bashan Tech LLC's internal legal notes (not published).

---

## Licensing in one paragraph

The scripts and configuration in this repository are open source. **The
artwork, logo, wallpapers and audio are not** — they are proprietary to
Bashan Tech LLC, and some of them have unconfirmed origins. The thousands of
programs that make up the system each keep their own licence, which is what
governs your use of them. Read [LICENSE](LICENSE) and [NOTICES.md](NOTICES.md)
before redistributing anything.

---

## Reporting problems

Say which machine, whether it was the live USB or an installed system, and
what you expected instead. Include the ISO's checksum so it is clear which
build you ran.
