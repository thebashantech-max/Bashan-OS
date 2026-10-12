# Changelog — Bashan OS

All notable changes to the build pipeline. Newest first.

## [Unreleased]

### Stage 5 — 2026-10-12
- Added the Bashan app wrapper: `bashan-app.desktop` (Brave app mode,
  `--app=https://bashan.app`, own WM class `bashan-app`), validated with
  `desktop-file-validate`.
- Added `scripts/20-bashan-app-icons.py`, generating 9 icon sizes (16-512 px)
  from `assets/branding/logo-source.jpg` with alpha derived from brightness so
  the cyan glow survives as a halo.
- **Verified by unpacking the Brave 1.97.56 deb: there is no
  `/usr/bin/brave-browser`, only `/usr/bin/brave-browser-stable`.** The
  launcher uses the correct name.
- Recorded measured limits of the source logo: real artwork is 374x532, so
  512 px is the clean ceiling. Documented in docs/DESIGN.md.
- Recorded the dock pinned order with verified desktop IDs, and flagged that
  the Chrome slot cannot render until Chrome is installed.
- `scripts/10-lb-config.sh` now also copies `apps/rootfs/` into the image.
- `assets/apps/bashan-app.zip` untouched, still gitignored, absent from the
  build tree.

### Stage 4 — 2026-10-12
- Added eight package lists: desktop (Plasma 6 minimal), firmware, browsers,
  apps, office, system-tools, fonts, i18n. 166 names total.
- Every name verified to have a real **installation candidate** in trixie, not
  merely to exist. Caught and fixed three that would have broken the build:
  `plasma-workspace-wayland` (folded into `plasma-workspace` in trixie),
  `fonts-kacst` (now `fonts-kacst-one`), `kimageformats` (now
  `kimageformat6-plugins`).
- Added Brave's official repo as a build-time **and** in-image archive, and
  Google Chrome's repo as in-image only, so no Chrome `.deb` is baked into the
  ISO. Vendor key fingerprints recorded in docs/BUILD.md.
- Added `hooks/rootfs/etc/xdg/baloofilerc` disabling KDE's file indexer by
  default.
- Measured: 1914 packages / 6533 MB installed with recommends on. Recommends
  account for 491 packages / 1911 MB. Trim candidates ranked in docs/APPS.md.
- Verified Akonadi and MariaDB are entirely absent (the Thunderbird decision).
- **I18N corrections from verification:** Persian *does* have spellcheck
  (`myspell-fa`) and a translated LibreOffice UI, contradicting the Stage 1
  note. Kurmanji has *no* LibreOffice-usable dictionary at all (`hunspell-ku`
  does not exist; `aspell-ku` is unusable by LibreOffice), which Stage 1 did
  not record. See docs/I18N.md.
- No ISO built. No idle RAM or boot figures measured.

### Stage 3 — 2026-10-12
- Added `packages/base.list.chroot` (42 packages; all names verified against
  the trixie archive inside the container).
- Added `scripts/10-lb-config.sh`, which regenerates the live-build tree from
  `packages/`, `hooks/chroot/` and `hooks/rootfs/`. Every `lb config` option
  verified accepted by live-build 1:20250505+deb13u1.
- Added tuning shipped as config files: zram (zstd, half RAM capped at 8 GB),
  `99-bashan-performance.conf` sysctls, and a per-disk-type I/O scheduler udev
  rule.
- Added `hooks/chroot/0100-trim-services.hook.chroot` (masks the wait-online
  units, disables systemd-networkd) and `0900-no-telemetry.hook.chroot`
  (purges telemetry packages and fails the build if any remain).
- `build.sh`: new `config` target; `container` now also installs live-build,
  debian-archive-keyring, xorriso and squashfs-tools inside the container.
- No ISO built yet. No boot time or RAM figures measured yet.

### Stage 2 — 2026-10-12
- Moved 4 loose duplicate files from `assets/` into `assets/_extra-copies/`
  (verified byte-identical to the filed copies; nothing deleted).
- Created the modular directory layout: `config/ packages/ branding/ theme/
  hooks/ installer/ i18n/ apps/ scripts/ assets/ build/ docs/`.
- Added `config/build.conf` as the single source of names and versions.
- Added `build.sh` with `container`, `in`, `build`, `test`, `clean`, `status`.
- Added `.gitignore` (build output, `assets/apps/`, secrets, ISOs).
- Added `docs/BUILD.md`, `DESIGN.md`, `I18N.md`, `APPS.md`, `CHANGELOG.md`.
- `git init`.
- Installed approved host tools: podman 4.9.3, mtools, shellcheck, inkscape,
  potrace, ffmpeg.
- Built and verified the trixie build container (`bashan-build`): archive
  reachable, `/work` writable, trixie `live-build` 1:20250505+deb13u1 and
  `mmdebstrap` 1.5.7 available inside. Approach B confirmed working; nothing
  from trixie installed on the Zorin host.
- `./build.sh test` passes: shellcheck clean. `clean` and `container` verified
  idempotent.
