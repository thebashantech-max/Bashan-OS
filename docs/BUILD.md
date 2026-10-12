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
To install (approved): `podman mtools shellcheck inkscape potrace ffmpeg`.

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
