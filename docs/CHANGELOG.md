# Changelog — Bashan OS

All notable changes to the build pipeline. Newest first.

## [Unreleased]

### Stage 7B — 2026-10-12
- Added the Calamares installer: `settings.conf`, 12 module configs and the
  Bashan branding (descriptor, four-slide QML slideshow, large-text
  stylesheet, generated artwork). All 14 YAML files parse-checked.
- Safety rules implemented and asserted: `initialPartitioningChoice: none`
  so nothing destructive is pre-selected, `prompt-install: true` for a
  second confirmation on top of the summary page, os-prober on for dual
  boot, and the erase option styled in red with plain-words consequences.
- Secure Boot carried through to the installed system via
  `efiBootloaderId` plus the signed packages already in the base list;
  `installEFIFallback: true` for firmware that ignores NVRAM entries.
- Added `packages/installer.list.chroot` (Calamares plus the Qt6 QML
  runtime it needs) and `install-bashan-os.desktop` launching via `pkexec`.
- Added `/etc/locale.gen` with all 13 shipped languages and
  `hooks/chroot/0300-locales.hook.chroot` to generate them. Every locale
  verified against glibc SUPPORTED: `syr` and `ckb_IQ` both exist;
  Kurmanji is `ku_TR` only; Persian is `fa_IR` with no `.UTF-8` form.
- **Installer translation coverage verified from upstream Calamares
  3.3.14:** 10 of 13 languages have an installer translation. Kurmanji,
  Sorani and Syriac have none. Arabic, Greek and Persian are in upstream's
  partial tier. System locale is unaffected — all 13 install fine. Table in
  docs/I18N.md.

### Stage 7A — 2026-10-12
- **Secure Boot fixed.** The build shipped no signed boot chain and would
  have failed to boot on any laptop with Secure Boot on. Added
  `shim-signed`, `grub-efi-amd64-signed`, `mokutil`, and
  `--uefi-secure-boot enable` so a missing signed binary fails the build
  loudly instead of producing an unbootable ISO. Kernel signing verified.
- Added the GRUB theme with two generated `.pf2` fonts, their internal
  names read back to confirm they match `theme.txt`.
- Added the Plymouth theme: resolution-aware logo that never upscales
  (574 px artwork, 815 px with halo, capped), a subtle pulse, and message
  and password callbacks so an encrypted install can be unlocked.
- Added the SDDM theme in plain QtQuick, plus `/etc/sddm.conf.d`.
- Added generated `os-release`, `issue`, `issue.net`, `motd` and
  `/etc/default/grub` with os-prober on for dual boot.
- Added `bashan-boot-sound.service`: raw ALSA, ordering-only so it can
  never block boot, holds the splash for the *remainder* of 5.5 s, with an
  on/off toggle and a documented way to swap the song.
- Added the boot song rights guard: a loud warning on every build, and a
  hard build failure if `PUBLIC_RELEASE=yes`. Tested — it does refuse.
- Leftover theme pieces: Konsole profile, fastfetch config with ASCII logo,
  cursor theme (alias of breeze_cursors), minimal Plasma desktop theme with
  the dock pill SVG. **Kvantum dropped for 1.0** — every Kvantum theme
  needs full SVG widget artwork; reasoning in docs/DESIGN.md.
- Fixed the cyan glow being clipped into a hard square: the halo is now
  padded before blurring, in both the icon and boot-logo generators.

### Stage 6 — 2026-10-12
- Added `theme/palette.json`, 24 design tokens. Accent sampled from the
  logo's cyan glow (hue 189).
- Added procedural wallpapers: 4K, 1080p and a darker login variant, from
  ridged fractal noise with perspective-correct frequency and dithering.
  Peak render memory measured at 621 MB.
- Added trash icons in two variants (A faithful, B text-free), 8 sizes each,
  extracted from the reference with a rounded-tile mask and component-based
  text removal. `TRASH_VARIANT` in `config/build.conf` selects one.
- Added the `Bashan` colour scheme, the `com.bashan.desktop` look-and-feel
  package with the dock layout, and icon theme indexes inheriting
  breeze-dark.
- Added the glowing `bashan-launcher` icon.
- Added the Google Chrome placeholder launcher and
  `/usr/bin/bashan-install-chrome`, with confirmation, progress and
  plain-language errors. Added `kdialog`, `pkexec`, `polkit-kde-agent-1`.
- Added `/etc/xdg/kdeglobals` so new accounts come up in the Bashan look.
- `scripts/10-lb-config.sh` now assembles the theme and picks the trash
  variant.
- All plasmoid ids verified against the Debian packages that ship them.
- Previews in `build/previews/`. **Mockups, not screenshots** — nothing has
  run Plasma yet.

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
