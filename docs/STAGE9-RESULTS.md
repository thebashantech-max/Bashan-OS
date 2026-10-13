# Stage 9 — first ISO build and QEMU test results

Build date 2026-10-12. **Private test build: the boot song is included and
its rights are unconfirmed. Do not distribute this ISO.**

| | |
|---|---|
| File | `build/out/Bashan-OS-1.0-amd64.hybrid.iso` |
| Size | 2.9 GB |
| SHA256 | `8e8e3400d91cf749aebd87fd72d79c83db831f2b5fd5045259cf7efc70f6efe6` |
| Compression | zstd level 15 (chosen over xz to keep peak build memory low) |

## The build failure, and what caused it

The first build died 80% through package installation, on
`dictionaries-common`, with an error about aspell and `/dev/null`.

**Root cause:** `/dev/null` inside the build chroot was an ordinary empty
file, not the null device. A rootless container cannot call `mknod`, so
debootstrap left a placeholder file. Hundreds of maintainer scripts redirect
to `/dev/null` and simply wrote into that file without complaining; the
first thing that actually broke was `aspell-autobuildhash`, which passes
`/dev/null` to aspell as a config file and got a parse error.

**Fix:** `scripts/51-chroot-devices.sh` bind-mounts the container's real
device nodes into the chroot (bind-mounting is permitted where `mknod` is
not). `build.sh` now runs live-build in three stages — bootstrap, chroot,
binary — so the devices can be put in place after the base system exists and
released again before the squashfs is made.

The chroot was rebuilt from scratch rather than resumed, because that broken
`/dev/null` had been in place while ~1900 packages configured themselves.
The 2.3 GB package cache was preserved, so the rebuild cost minutes, not a
re-download.

## Secure Boot — verified twice

**Statically**, by unpacking the ISO:

| File | What it is | Signature |
|---|---|---|
| `/EFI/boot/bootx64.efi` | Debian's **shim** | 19,360-byte Authenticode (Microsoft) |
| `/EFI/boot/grubx64.efi` | signed **GRUB** | 1,472-byte Authenticode (Debian) |

**At runtime**, by booting QEMU with `OVMF_CODE_4M.ms.fd` — the firmware
image with Microsoft's keys actually enrolled, plus `smm=on` and the
pflash secure flag. The system booted to a desktop. This is a real Secure
Boot test, not a simulation.

## Measured numbers

Measured inside the VM: 2 vCPU, 2048 MB RAM, KVM acceleration, virtio.

| Measurement | Value |
|---|---|
| Boot time | **6.93 s** total — 2.88 s kernel + 4.05 s userspace |
| `graphical.target` reached | 4.05 s into userspace |
| CPU at idle | **97-98% idle** (2% user, 1% system) |
| Memory in use, live session | 1399 MB of 1935 MB |

**The memory figure is not the installed-system figure** and must not be
quoted as one. A live ISO decompresses the squashfs into page cache as it
runs, so a live session always reports far more memory in use than the same
system installed to disk. A real idle-RAM number needs a completed
installation, which is Stage 10 work.

Boot time is also optimistic: this is KVM with virtio on an NVMe-backed
host. An older laptop with a spinning disk will be several times slower.

## What works

- Boots under UEFI **with Secure Boot on**
- **Plymouth splash shows the Bashan glowing logo** on black, correctly
- Wallpaper, floating dock pill, logo launcher, system tray and clock all
  render as designed
- `os-release` branding: Plasma's own welcome text reads "Welcome to the
  Bashan OS operating system"
- Look-and-feel `com.bashan.desktop` is the active theme
- Boot-sound service: `enabled`, `active`, `Result=success`, exit 0
- First user has the right groups: sudo, audio, video, netdev, bluetooth…
- **Per-language fonts resolve exactly as designed** (`fc-match`):
  - Arabic → Noto Sans Arabic, then Scheherazade
  - Syriac → **Estrangelo Edessa**, then Serto Jerusalem
  - Hebrew → Noto Sans Hebrew
- `/usr/bin/brave-browser-stable` exists and launches — the Stage 5 finding
  about the binary name was correct
- Calamares loads, fully branded: "Bashan OS Installer", our logo in the
  sidebar and banner, "Bashan Tech LLC", our step names, dark styling
- Calamares' storage requirement works: on an 8 GB disk it refused with
  "There is not enough drive space. At least 20 GiB is required" and
  **Next stayed greyed out**

## Defects found

| # | Defect | Severity | Status |
|---|---|---|---|
| 1 | Build failed on `/dev/null` in the chroot | blocker | **fixed, rebuilt** |
| 2 | Calamares refused to start: `bootloader-config` is not a real module | blocker | **fixed and re-tested live — installer now runs** |
| 3 | The ISO's own boot menu is stock Debian, not Bashan | cosmetic | **fix written**, needs rebuild |
| 4 | Plasma's startup splash is stock KDE ("Plasma made by KDE") | cosmetic | not fixed |
| 5 | KDE's Welcome Center opens on first boot | annoyance | not fixed |
| 6 | IBus pops up a notification about Wayland on first boot | annoyance | not fixed |
| 7 | Chrome placeholder shows a blank document icon | cosmetic | not fixed |
| 8 | Only the system-monitor desktop widget appeared; weather and notes did not, and none honoured the positions set in the layout | real | not fixed |
| 9 | The Trash widget never appeared on the desktop, so the RTL corner logic is untested | real | not fixed |
| 10 | **The installer's disk page was unreadable** — light text on a light panel | serious | **fixed and re-tested live** |

### On defect 3

The ISO's boot menu and the installed system's boot menu are two different
things built by two different mechanisms. `branding/grub/bashan/` and
`/etc/default/grub` only affect the machine **after** installation.
live-build builds the ISO's own menu from `config/bootloaders/`. The fix
adds `config/bootloaders/grub-pc/` (UEFI menu theme plus splash) and
`config/bootloaders/isolinux/splash.png` (BIOS menu).

### On defects 8 and 9

The `widget.geometry = Qt.rect(...)` calls in the Plasma layout script were
flagged as unverified when written, and they are indeed being ignored.
Desktop widget placement needs a different approach. Until the Trash widget
appears at all, the right-to-left corner switching in
`bashan-desktop-locale` cannot be tested.

### On defect 10 — the worst one found

The partition page rendered its three options as near-invisible text. Cause:
Calamares runs as **root**, so it does not inherit the user's Plasma colour
scheme; Qt gave it a default **light** palette, and our stylesheet's light
text sat on top of it. The fix sets an explicit dark background in the
stylesheet instead of relying on the scheme, plus visible radio indicators.

Verified by patching the stylesheet inside the running live session and
relaunching the installer: the options are now legible, with "delete"
still highlighted in red on the erase option.

## The safety rules, tested on a real run

With a 60 GB disk containing an existing GPT/ESP layout:

| Rule | Result |
|---|---|
| Nothing destructive pre-selected | **PASS** — all three radio buttons empty on arrival |
| Next disabled until a deliberate choice | **PASS** — Next greyed out |
| Erase option clearly marked | **PASS** — "This will **delete** all data currently present on the selected storage device", delete in red |
| Minimum storage enforced | **PASS** — on an 8 GB disk it refused outright: "There is not enough drive space. At least 20 GiB is required", Next disabled |
| Dual boot offered | **NOT PROVEN** — see below |

**Dual boot could not be confirmed.** "Install alongside" did not appear,
but that is a limitation of the test fixture, not evidence of a fault: the
fake Windows disk contains a text file where `bootmgfw.efi` should be and
has no real filesystem on its data partition, so `os-prober` correctly
found no operating system to install alongside. Proving this needs a disk
with a genuine bootable OS on it.

## Both firmware modes boot

| Mode | Result |
|---|---|
| UEFI with **Secure Boot ON** | **PASS** — boots to desktop |
| Legacy BIOS | **PASS** — boots to the same desktop, branding intact |

## Not yet tested

- Dual boot being offered on a disk with a genuinely bootable OS on it (the
  other partition-page rules all passed; see the safety-rules table above)
- `xprop` window class of the Bashan app (Brave would not start in a 2 GB VM
  on top of a live session)
- Arabic and Syriac rendering on screen (fonts resolve correctly, but no
  text has been displayed in those scripts)
- The Chrome placeholder's install flow
- SDDM login screen: the live session auto-logs in, so the greeter never
  appeared
