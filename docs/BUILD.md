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
