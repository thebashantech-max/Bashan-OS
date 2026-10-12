# Building Bashan OS 1.0

Publisher: Bashan Tech LLC. Base: clean minimal Debian 13 (trixie), x86_64.
Output: `Bashan-OS-1.0-amd64.hybrid.iso` (hybrid UEFI + BIOS).

## Approach

**Approach B (chosen):** all build work happens inside a Debian trixie container
on the Zorin host via podman. Trixie `live-build` and `debian-archive-keyring`
are never installed on the host. Approach A (host build) is the fallback only,
and only with the owner's approval.

## Host requirements

Already present: `git`, `xorriso`, `qemu-system-x86_64`.
Installed 2026-10-12 (approved): `podman` (4.9.3), `mtools`, `shellcheck`,
`inkscape`, `potrace`, `ffmpeg`.

## Container — verified 2026-10-12

Image `docker.io/library/debian:trixie-slim`, container `bashan-build`,
rootless podman, project bind-mounted at `/work`, running as root inside
(mapped to the host user, so files it creates stay owned by `simple`).

Verified: Debian GNU/Linux 13 (trixie) inside; archive reachable; writes to
`/work` succeed; `./build.sh container` reuses an existing container instead of
recreating it. Build packages confirmed available **from trixie, inside the
container only**:

| Package | Version in trixie |
|---|---|
| `live-build` | 1:20250505+deb13u1 |
| `mmdebstrap` | 1.5.7-1+deb13u1 |
| `debian-archive-keyring` | 2025.1 |
| `xorriso` | 1.5.6-1.2+b1 |
| `squashfs-tools` | 1:4.6.1-1 |
| `grub-efi-amd64-bin` | 2.12-9+deb13u2 |

The container is created `--privileged` so it can later build filesystem images
and loop-mount. Its only host mount is this project directory.

## Commands

```
./build.sh status      # show config and container state
./build.sh container   # create + verify the trixie build container (idempotent)
./build.sh config      # regenerate the live-build tree from this repo
./build.sh in bash     # shell inside the container, project at /work
./build.sh test        # shellcheck every script
./build.sh clean       # wipe build/work and build/out, keep logs
./build.sh build       # full ISO build (lands Stage 9)
```

Logs: `build/logs/<timestamp>-<target>.log`, one per run.

## Layout

| Directory    | Holds |
|--------------|-------|
| `config/`    | `build.conf` — names, version, suite, mirror, container image |
| `packages/`  | package lists per group (base, desktop, office, tools…) |
| `branding/`  | generated os-release, GRUB, Plymouth, SDDM, logos |
| `theme/`     | Plasma look-and-feel, Kvantum, icons, cursors, Konsole, fastfetch |
| `hooks/`     | chroot hooks (tuning, zram, sysctl, IO scheduler, first-login) |
| `installer/` | Calamares config and branding |
| `i18n/`      | translations for all Bashan-specific strings (13 languages) |
| `apps/`      | Bashan app `.desktop` wrapper and icon (never the app source) |
| `scripts/`   | stage scripts called by `build.sh` |
| `assets/`    | owner-supplied source art and audio (not all tracked) |
| `build/`     | `work/`, `out/`, `logs/` — all ignored by git |
| `docs/`      | this file, DESIGN.md, I18N.md, APPS.md, CHANGELOG.md |

## Rules

- Scripts stay shellcheck-clean and idempotent; `./build.sh test` enforces it.
- Never run a build and a QEMU test at the same time (host has ~3.3 GB free RAM).
- Never write to a block device without showing `lsblk` and getting explicit
  confirmation first.
- No secrets in git. `assets/apps/` is gitignored and never enters the ISO.


## Stage 3 — base system and tuning

### How a build is assembled

`./build.sh config` runs `scripts/10-lb-config.sh` inside the container. That
script wipes and regenerates `build/work/lb/`, then grafts this repository in:

| Source in repo | Lands in live-build tree as |
|---|---|
| `packages/*.list.chroot` | `config/package-lists/` |
| `hooks/chroot/*.hook.chroot` | `config/hooks/normal/` |
| `hooks/rootfs/**` | `config/includes.chroot/` (copied verbatim into the image) |

The tree is disposable output under `build/work/`, so it is gitignored. The
repository holds the sources; the tree is always regenerated from them.

### ISO settings (verified accepted by live-build 1:20250505+deb13u1)

`trixie` / `amd64`, archive areas `main contrib non-free non-free-firmware`,
`iso-hybrid` image with `grub-efi` + `syslinux` (UEFI and BIOS), firmware
included in both chroot and binary, Debian Installer disabled (Calamares
instead), memtest off, security and updates repos on. ISO application
"Bashan OS", publisher and preparer "Bashan Tech LLC", volume "Bashan OS 1.0".

### Base package list

`packages/base.list.chroot` — 42 packages, every name verified to resolve in
the trixie archive. Kernel, both bootloaders, systemd plumbing, NetworkManager,
the common filesystems, locale/console, and a minimal console rescue toolset.
Desktop, browsers, office, fonts and language packs are Stage 4.

### Tuning — what each piece does

**zram** (`hooks/rootfs/etc/systemd/zram-generator.conf`) — creates compressed
swap inside RAM: half of physical memory, capped at 8 GB, zstd. Priority 100 so
it is always used before any disk swap.

**sysctl** (`hooks/rootfs/etc/sysctl.d/99-bashan-performance.conf`) —
`swappiness=180` and `page-cluster=0` are the pairing zram wants;
`vfs_cache_pressure=50` keeps file-browsing metadata hot; `dirty_bytes` /
`dirty_background_bytes` replace the percentage defaults so large file copies
flush steadily instead of stalling the machine; `max_map_count` and the inotify
limits are raised to what games and modern desktop tooling expect;
`nmi_watchdog=0` drops a per-CPU timer interrupt; `fq_codel` + `bbr` stop a
large upload from ruining a video call.

**I/O scheduler** (`hooks/rootfs/etc/udev/rules.d/60-bashan-ioscheduler.rules`)
— NVMe gets `none`, SATA/USB SSDs get `mq-deadline`, spinning disks get `bfq`.

**Service trim** (`hooks/chroot/0100-trim-services.hook.chroot`) — masks
`NetworkManager-wait-online` and `systemd-networkd-wait-online` (they make boot
wait for the network for no desktop benefit) and disables `systemd-networkd`,
which otherwise fights NetworkManager over the same interfaces. Deliberately
conservative: nothing touching printing, Bluetooth or security updates.

**No telemetry** (`hooks/chroot/0900-no-telemetry.hook.chroot`) — purges
`popularity-contest`, `apport`, `whoopsie`, `ubuntu-report`, `reportbug` if
anything pulled them in, then **fails the build** if any survived, so the
no-telemetry promise cannot silently regress.

### Not yet measured

Boot time, idle RAM and the real effect of this tuning are measured at Stage 9
against a booted ISO. Nothing in this section has been benchmarked yet.


## Stage 4 — desktop, firmware, apps

### Package lists

| List | Names | Covers |
|---|---:|---|
| `base.list.chroot` | 42 | kernel, bootloaders, systemd, NetworkManager, filesystems |
| `desktop.list.chroot` | 29 | Plasma 6 minimal, SDDM, PipeWire, graphics stack |
| `firmware.list.chroot` | 23 | Wi-Fi, Bluetooth, graphics, audio, CPU microcode |
| `browsers.list.chroot` | 1 | Brave |
| `apps.list.chroot` | 10 | Thunderbird, Dolphin, Konsole, Kate, Ark, Okular, Gwenview, Spectacle, KCalc, Kamoso |
| `office.list.chroot` | 29 | LibreOffice + Qt6/KDE integration + translations + dictionaries |
| `system-tools.list.chroot` | 15 | Discover/Flatpak, printing, firewall, partitioning, Timeshift, fastfetch |
| `fonts.list.chroot` | 12 | one entry per shipped script |
| `i18n.list.chroot` | 5 | locales and input methods |

**All 166 names verified to have a real installation candidate in trixie.**
Name existence alone is not enough: `apt-cache show` succeeds for transitional
packages that cannot be installed. `plasma-workspace-wayland`, `fonts-kacst`
and `hunspell-ku` all passed a name check and failed the candidate check.

### Plasma 6 minimal

`plasma-desktop`, not the `kde-plasma-desktop` or `kde-full` tasks, which drag
in Kontact and the whole Akonadi stack. In trixie `plasma-workspace` ships
**both** the Wayland and the X11 session — there is no separate
`-wayland` package. X11 remaining available at the login screen is the safety
net for older laptops where Wayland and nouveau misbehave.

### Third-party repositories

live-build treats archive files by suffix, and the difference matters:

| File | Effect |
|---|---|
| `config/archives/brave-browser.list` (no suffix) | used **during the build** (Brave is baked into the ISO) **and** left in the installed system, so Brave keeps getting security updates |
| `config/archives/brave-browser.key` | key, installed in both stages |
| `config/archives/google-chrome.list.binary` | written into the finished image **only** — never used during the build, so no Chrome `.deb` is baked in |
| `config/archives/google-chrome.key.binary` | key, final image only |

A `.list.chroot` suffix would have been wrong for Brave: live-build **deletes**
those from the final image, so Brave would have installed but never updated.

Both keys were downloaded from the vendors and their fingerprints recorded:

- Brave `DBF1A116C220B8C7164F98230686B78420038257`
- Google `EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796`

Verified: with these repos configured, `brave-browser` and
`google-chrome-stable` both resolve and apt validates their signatures. Chrome
is confirmed **absent** from the resolved install set.

Caveat: live-build installs repo keys into `/etc/apt/trusted.gpg.d/`, which is
system-wide trust. The `signed-by=` option in each list scopes which key
validates which repo, but the keys remain globally trusted. Moving them to
`/usr/share/keyrings/` would need an extra hook; not done for 1.0.

### Firmware for the target laptop

The target is an older laptop installed from USB, so firmware must be on the
stick, not downloaded. `firmware-b43-installer` and `firmware-b43legacy-installer`
are deliberately **excluded**: they fetch firmware from the network at install
time and fail offline. Broadcom cards are covered by `firmware-brcm80211`
instead. CPU microcode for both Intel and AMD is included.

### Sizes and indexers

See `docs/APPS.md` for the measured per-group sizes, what Recommends cost, the
ranked trim candidates, and the Akonadi/Baloo findings.


## Secure Boot — verified, Stage 7A

**Short answer: yes, it will boot with Secure Boot on — but only because
this stage fixed it. The Stage 3/4 configuration would not have.**

### What was wrong

The base list shipped `grub-efi-amd64-bin` and nothing else. On a laptop
with Secure Boot enabled — the factory default on essentially every machine
since about 2012 — the firmware refuses to run an unsigned bootloader. The
machine would have shown "Secure Boot violation" or simply dropped back to
the firmware menu, and the only fixes available to the user would have been
to turn Secure Boot off in the BIOS or to reinstall.

### The chain, and what each link needs

| Link | Package | Status |
|---|---|---|
| Firmware loads a Microsoft-signed shim | `shim-signed` | **added at Stage 7A** |
| shim loads Debian-signed GRUB | `grub-efi-amd64-signed` | **added at Stage 7A** |
| GRUB loads a signed kernel | `linux-image-amd64` | already correct |
| User can manage keys if needed | `mokutil` | added |

The kernel was verified, not assumed: `linux-image-amd64` resolves to
`linux-image-6.12.107+deb13-amd64`, whose `Source:` is `linux-signed-amd64`.
Debian publishes a separate `-unsigned` flavour, and we are not using it.

### The ISO itself

`scripts/10-lb-config.sh` now passes `--uefi-secure-boot enable`. live-build
supports three modes; the default `auto` does a best-effort build and
silently produces a **non-Secure-Boot ISO** if the signed binaries are
missing. `enable` makes the build fail instead, which is what we want: a
loud failure at build time beats a laptop that will not boot.

With this, live-build installs shim as `BOOTX64.EFI` on the ISO, which is
what the firmware loads first.

### Remaining caveats

1. **Unverified until Stage 9.** The packages and the live-build switch are
   confirmed correct; that the resulting ISO actually boots a
   Secure-Boot-enabled machine is a QEMU test with OVMF + Secure Boot on.
2. **No third-party kernel modules.** Everything we ship is in-tree
   (nouveau, iwlwifi and friends are all mainline), so nothing needs MOK
   enrolment. If an NVIDIA proprietary driver is ever added, the user would
   have to enrol a key manually at first boot.
3. **BIOS machines are unaffected.** Secure Boot is a UEFI feature; the
   syslinux BIOS path is unchanged.

### If it still fails on the target laptop

In order of preference: check the firmware is in UEFI rather than Legacy/CSM
mode; check the firmware's Secure Boot key database is not set to
"Custom"/cleared (reset to factory keys); and only as a last resort disable
Secure Boot in the firmware.

## Stage 7A — boot chain branding

| Piece | Where it lives | Notes |
|---|---|---|
| GRUB theme | `branding/grub/bashan/` | background, logo, `theme.txt`, two generated `.pf2` fonts |
| Plymouth theme | `branding/plymouth/bashan/` | script plugin, five logo sizes, gradient strip |
| SDDM theme | `branding/sddm/bashan/` | plain QtQuick QML, no SddmComponents |
| os-release, issue, motd | generated in `10-lb-config.sh` | from `config/build.conf`, so they cannot drift |
| `/etc/default/grub` | `branding/rootfs/` | theme, `quiet splash`, os-prober ON for dual boot |
| Boot sound | `branding/rootfs/` | service, script, config, WAV |
| Activation | `hooks/chroot/0200-boot-branding.hook.chroot` | sets the Plymouth theme and rebuilds the initramfs |

### GRUB fonts

`theme.txt` references `DejaVu Sans Regular 16` and `24`. Those are not
names GRUB knows by default — a GRUB theme needs real `.pf2` font files.
Both are generated with `grub-mkfont` and their internal names read back
out of the binaries to confirm they match what `theme.txt` asks for.

No pixmap styles are used. GRUB's nine-slice pixmaps are fragile and a
mis-sliced highlight looks far worse than clean colour.

### Plymouth logo scaling

The artwork is 574 px; with its glow halo the image is 815 px. The script
draws the image at `min(0.40 * screen_height, 815)`, putting the artwork at
28% of screen height and **never upscaling**.

| Panel | Artwork drawn at | % of height | Asset used |
|---|---:|---:|---|
| 1366x768 | 216 px | 28.2% | 384 px, downscaled |
| 1920x1080 | 304 px | 28.2% | 512 px, downscaled |
| 2560x1440 | 406 px | 28.2% | 640 px, downscaled |
| 3840x2160 | 574 px | 26.6% | 815 px, native, no scaling |

So the soft-at-4K problem does not arise: at 4K the logo is drawn at exactly
its native pixels. The only cost is that it covers 26.6% of the screen
instead of 28%, a difference nobody will see.

The theme also implements the message and password callbacks. Without them
an encrypted install would stop at a black screen with no way to type the
passphrase.

### Boot sound

`bashan-boot-sound.service` is ordered `Before=plymouth-quit.service` and
`After=plymouth-start.service`, with **no** `Requires` anywhere, so nothing
depends on it and a failure cannot stop the boot. `TimeoutStartSec=12`
bounds it.

It plays through raw ALSA (`aplay`), because at that point in boot no user
session exists and PipeWire is not running.

The splash hold waits only the **remainder** of 5.5 s measured from
`/proc/uptime`. On a machine that already took 6 s to get there it adds
nothing at all.

`RemainAfterExit=yes` keeps the unit active so the backgrounded `aplay` is
not killed with its cgroup the moment the script returns, which would cut
the song off after a fraction of a second.

Toggle: `ENABLED=no` in `/etc/bashan/boot-sound.conf` (splash still holds,
so boot looks identical), or `systemctl disable bashan-boot-sound`.
Swap the song: drop a WAV at `/etc/bashan/boot-song.wav`, which takes
priority over the shipped file and survives updates.

### Boot song rights guard

The song is 4.87 s, converted to 48 kHz stereo WAV. Rights are **not
confirmed**, so:

* `INCLUDE_BOOT_SONG=yes` prints a loud warning on every single build.
* `INCLUDE_BOOT_SONG=yes` together with `PUBLIC_RELEASE=yes` **aborts the
  build** with an explanation. Tested: the build does refuse.
* `INCLUDE_BOOT_SONG=no` omits the audio and still holds the splash, so a
  clean public build looks identical minus the sound.
