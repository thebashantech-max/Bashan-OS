# Changelog — Bashan OS

All notable changes to the build pipeline. Newest first.

## [Unreleased]

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
