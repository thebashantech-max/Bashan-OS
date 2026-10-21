# Changelog — Bashan OS

All notable changes to the build pipeline. Newest first.

## [Unreleased]

### Approved trims applied — 2026-10-13
- `fonts-noto-cjk-extra` pinned out: **209.8 MB**, the extra CJK weights.
  `fonts-noto-cjk` (89.1 MB) is **kept** so CJK text on a web page still
  renders as characters rather than empty boxes.
- `cups-browsed` pinned out: 0.4 MB, but it is a **listening daemon** for
  discovering remote CUPS print servers and the component behind the 2024
  remote-code-execution family. Driverless IPP through avahi still finds
  modern printers. The saving is attack surface, not disk.
- Both verified a Recommends, not a Depends: `apt-get remove -s` reported
  exactly one package each.
- `fonts-noto-cjk`, `smartmontools` and `avahi-daemon` added to the hook's
  KEEP assertions, so a future over-eager trim fails the build instead of
  silently removing them.

### Hardware record for Dad's laptop — 2026-10-13
- Added `docs/HARDWARE-TEST-DAD-LAPTOP.md`, with every field marked TO FILL
  and a standing warning that the results come from the OLD Zorin-based
  prototype and are **hardware evidence only, not a test of Bashan OS**.
- Added `docs/HARDWARE-COLLECT.md`: copy-paste, read-only commands that
  write one text file. Nothing writes to a disk or changes a setting.
- Added `docs/PRE-INSTALL-CHECKLIST.md`, which flags that **"Install
  alongside" has not been proven to work** in this build, so a dual-boot
  machine must not be the place it is first tried.

### Part F — privacy and proxy tools — 2026-10-13
- Added `packages/privacy.list.chroot`: `torbrowser-launcher`, `tor`,
  `proxychains4`, `wireguard-tools`, `openvpn`, `network-manager-openvpn`.
  **69.2 MB, 33 packages, zero idle cost.** All verified in trixie.
- `hooks/chroot/0320-tor-disabled.hook.chroot` disables and masks the tor
  daemon and **fails the build if it is enabled**, so it costs no idle RAM
  and opens no socket. Tor Browser carries its own tor and is unaffected.
- Verified NetworkManager 1.52 speaks WireGuard natively (no plugin) and
  that `wireguard.ko.xz` ships with the stock Debian kernel, so a `.conf`
  imports from the Plasma network applet with no terminal.
- Added a 7th welcome-app page in all 13 languages: what a VPN is, that it
  needs a server Bashan OS does not provide, that free VPN services often
  log and sell, that Tor is slower and that some sites block it.
  REVIEW.csv is now 828 rows.
- Added `docs/PRIVACY-TOOLS.md` (exactly what torbrowser-launcher downloads
  and from where) and `docs/WIREGUARD-HOME-SERVER.md` (a full guide to
  running a WireGuard server at home, including the CGNAT case and the
  honest warning that it opens a port).
- **No VPN service, no bundled server list, nothing needing registration.**

### Part E — security and performance — 2026-10-12

**Approved corrections first**
- Pinned 6 packages to priority -1 and added
  `hooks/chroot/0920-excluded-packages.hook.chroot`, which **fails the
  build** if any reappears: the three b43 packages that download firmware
  over the internet at install time, two unused non-free astronomy camera
  libraries, and the non-free Meltho Syriac fonts.
- **Syriac now renders in Noto Sans Syriac** (OFL-1.1, `fonts-noto-extra`).
  The hook fails the build if that font is missing, so Syriac can never
  silently become boxes.
- **Google's apt repository now ships disabled** as
  `google-chrome.list.disabled`. An untouched machine never contacts
  `dl.google.com`. The installer enables it only after a dialog that
  explains the consequence in the user's own language, disables it again if
  the install fails, and `chrome-placeholder-sync` disables it and restores
  the one-click launcher if Chrome is later removed.
- **Firmware trimmed by 283.2 MB**, 13 packages, all datacenter, telephony
  or television hardware. Each verified to arrive via a Recommends, never a
  Depends. The hook asserts the 15 packages a laptop needs survived.

**Found and fixed: the installer slideshow was broken**
- `scripts/40-i18n.py` appended its generated block on every run instead of
  replacing it. `show.qml` had reached **six** `readonly property var tr`
  declarations in one QML object — a syntax error; the slideshow would not
  have loaded. Four of the six predate this session. The generator now uses
  explicit BEGIN/END markers and is idempotent (proved by running it three
  times). 974 lines down to 268.

**Part E proper**
- Firewall on, `DROP` inbound, `ACCEPT` outbound, GUI present.
- Automatic updates from the **security archive only**, which **cannot
  reboot the machine** — the build fails if that is ever changed. A user
  timer sends one plain-words notification instead.
- Pre-update Timeshift snapshots, which no-op safely until the user sets
  Timeshift up (it cannot be preconfigured without a target disk).
  `docs/ROLLBACK.md` explains both in plain words.
- Disk-encryption warning added as a 5th slideshow slide in 13 languages;
  Calamares has no supported way to put custom text on its partition page.
- Hardening: root locked, no SSH server (build fails if one appears), sudo
  `use_pty`/`env_reset`/`secure_path`, 10-minute screen lock, and 20
  desktop-safe kernel sysctls. Three hardening settings deliberately NOT
  applied, each with its reason recorded.
- Brave telemetry, crash reporting and stats pings off by policy.
- **Measured: 0 pending security updates**, 0 upgradable. Only
  `avahi-daemon` listens on the network; CUPS is localhost-only.
- `docs/SECURITY.md` and `docs/LAPTOP-TEST.md` added.

### Part D — legal drafts — 2026-10-12
- Added `docs/legal/`: NOTICE.md, TERMS.md, PRIVACY.md,
  Bashan Tech LLC's internal legal notes (not published), COOKIES.md. Each marked "DRAFT - not legal
  advice". Nothing published.
- Written from **measured facts**, not boilerplate. The built image has
  2,106 packages; 3 from contrib, 4 from non-free, 36 non-free-firmware,
  all enumerated by name.
- **Found: `firmware-b43-installer`, `firmware-b43legacy-installer` and
  `b43-fwcutter` are in the image** although `firmware.list.chroot` says in
  a comment they are deliberately excluded. They download Broadcom firmware
  from the internet at install time, which fails on the stated target (a
  laptop installed from USB, offline), and nothing depends on them.
- **Found: `libfishcamp1t64` and `libsbig4t64`** (non-free astronomy camera
  libraries) are installed with nothing depending on them.
- **Found: Syriac renders in a non-free font by our own choice.** The Meltho
  licence permits redistribution but forbids modification, which is why
  Debian classes it non-free. `fonts-noto-extra` is already installed and
  provides Noto Sans Syriac under OFL-1.1; only one fontconfig line makes
  the non-free font win. A one-line decision either way.
- **Found: `dl.google.com` is contacted on every update check** because
  Google's repository is preconfigured, even though Chrome is never
  installed. Documented prominently in PRIVACY.md.
- Only 14 of the 36 non-free-firmware packages were asked for; 22 arrived
  via the `firmware-linux` metapackage.
- Legal documents are installed to `/usr/share/doc/bashan/legal/`, the exact
  path the welcome app's page 6 opens, and the welcome hook now fails the
  build if any of the three is missing.

### Part C — the welcome app — 2026-10-12
- Added "Get to Know Bashan OS": plain QML, six pages, run by the `qml`
  runner from `qml-qt6`. **Total cost 0.1 MB**, because QtQuick, Controls,
  Layouts, QtCore and QtMultimedia were already in the image. PyQt6 would
  have cost 17.9 MB and PySide6 86.4 MB.
- Recorded a trap: the `qml` runner is **not** in
  `qt6-declarative-dev-tools` (that has qmllint/qmlformat and no runtime).
  It is in `qml-qt6`, found via Debian's Contents index.
- Opens on **first login only** by default; the "Show this when I start the
  computer" box is an opt-in and starts unticked. Reopenable from the
  launcher. The autostart path cannot hold up a login.
- **Purges `plasma-welcome`** (Stage 9 defect 5) rather than guessing at its
  autostart trigger. Verified a Recommends, not a Depends: exactly one
  package removed. The hook fails the build if it survives.
- 41 new strings x 13 languages = 533 translations. `i18n/REVIEW.csv` is now
  732 rows. The app **displays the current language's confidence on screen**
  when it has not been reviewed by a native speaker.
- QML cannot start a process, so three buttons open a `bashan-action:` URL
  handled by `/usr/bin/bashan-action`. The startup-sound switch goes through
  `pkexec` because `/etc/bashan/boot-sound.conf` is root-owned.
- Welcome music plays once on page 1, never loops, visible mute button,
  under the same rights guard as the boot song. Swappable at
  `/etc/bashan/welcome-song.wav`, which survives updates.
- **Screenshotted for real under Xvfb**, every page, English and Arabic,
  dark and light. That found three defects reading the code would not have:
  Qt 6 blocks `file://` XHR so every string rendered as its key; the Basic
  style's checkbox indicators were invisible on dark; and all controls used
  the stock palette. All three fixed. `qmllint`: 0 errors.
- Arabic RTL mirroring verified by screenshot, not assumed.

### Part B — dark and light — 2026-10-12
- Added `theme/palette-light.json`, the same 37 token names as the dark
  palette so every generator reads either file with no special case.
- Added `scripts/_palette.py`: shared variant loader plus a WCAG contrast
  check over 11 text/background rules in both variants. Wired into
  `./build.sh test`, so a palette edit that makes text unreadable fails.
- The dark accent `#22d3ee` measures 1.65:1 on white and could not be
  reused; the light accent is `#0e7490` at 4.99:1.
- Made four generators variant-aware (wallpaper, theme package, desktop
  theme, icons). **Dark output regenerates byte-identical** — verified, not
  assumed.
- Moved 8 hardcoded render constants into palette tokens (`wall_*`,
  `dock_*`, `glow_*`), so the light scene is a palette change not a branch.
- Ships both look-and-feel packages, so System Settings > Global Theme
  offers the switch with no custom UI.
- Added `bashan-theme-toggle` + launcher entry. It switches scheme, desktop
  theme, wallpaper and icon theme separately rather than applying a
  look-and-feel, because applying one re-runs its layout and would destroy
  the user's dock and widgets.
- Added day/night timers, **disabled by default** (`docs/THEME-DAYNIGHT.md`).
- Light wallpapers add ~10.8 MB uncompressed; mksquashfs deduplicates, and
  the real ISO cost is measured in Part G.

### Part A — viewers, converters, editors — 2026-10-12
- Added `vlc`, `gimp`, `kdenlive`, `kolourpaint`, `converseen`, `handbrake`
  to `packages/apps.list.chroot`. All six resolve in trixie, so neither
  converter fallback was needed. **+543.5 MB installed, 129 new packages**,
  measured against the real chroot rather than estimated.
- Added **nothing** for HEIC, AVIF, JPEG XL, WebP, TIFF or RAW: all are
  already provided by `kimageformat6-plugins` and
  `qt6-image-formats-plugins` from Stage 4. Same for audio/video codecs.
  `libavcodec-extra` deliberately skipped.
- Added `/etc/xdg/mimeapps.list`: 87 default-app associations — photos to
  Gwenview, video and audio to VLC, PDFs to Okular.
- Added `scripts/52-check-defaults.sh`, which validates every `.desktop` id
  and MIME name against what the installed system will really have. It
  caught three real defects on first run, including the same image format
  assigned to two different apps. shellcheck-clean.
- Measured each new binary for phone-home behaviour. **GIMP** and
  **Converseen** both contain update-check URLs and are now switched off via
  `/etc/skel`; VLC's first-run network dialog and album-art lookup are off.
  Kdenlive, KolourPaint and HandBrake had no such URL in their shipped files.
- Pinned KDE's `PlasmaUserFeedback` to level 0 system-wide.
- None of the six adds idle RAM: no daemons, no autostart entries.
- Nothing pinned to the dock.

### Stage 8 — 2026-10-12
- Added `i18n/strings.json`: 20 Bashan-specific strings in all 13 languages,
  260 entries, each language carrying an honest confidence rating.
- Added `scripts/40-i18n.py`, generating the `.desktop` translations, 13
  shell catalogues for the Chrome installer, the slideshow's embedded
  translation map, and `i18n/REVIEW.csv` (240 rows) for native-speaker
  review.
- `bashan-install-chrome` now speaks the user's language, falling back to
  English per string.
- **Every build warns** which languages are unreviewed. Kurmanji and Sorani
  are LOW confidence, Syriac VERY LOW; none has been checked by a native
  speaker and the docs say so plainly.
- Added `/etc/fonts/conf.d/60-bashan-languages.conf`, 11 rules covering
  Arabic, Persian, Sorani, Hebrew and Syriac. Family names read with
  `fc-query` — trixie ships `Scheherazade`, not `Scheherazade New`.
- Added `bashan-desktop-locale`: puts the Trash icon bottom-right for the
  eight LTR languages and bottom-left for the five RTL ones, re-running on
  a language change. Uses plasmashell's D-Bus scripting API rather than
  editing Plasma's internal config format. Added `qdbus-qt6`.
- Added the Trash widget to the desktop layout.
- The installer's welcome image now carries the "installer not available in
  your language" note in English, Kurmanji, Sorani and Syriac, rendered
  through Pango so Arabic and Syriac are shaped and ordered correctly.
- Replaced the post-install username guess with
  `bashan-seed-user <username>`, called by Calamares with the account it
  actually created.

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
