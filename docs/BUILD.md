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
