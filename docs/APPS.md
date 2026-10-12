# Bashan OS — Preinstalled Applications

Lean by intent. Installed size and idle RAM are measured and recorded per group
as each group lands (Stage 4).

## Groups

**Office** — LibreOffice Writer, Calc, Impress, Draw, Base, Math, with Qt
integration and dictionaries.

**Internet** — Brave (baked in from Brave's official apt repo). Thunderbird for
mail, calendar and contacts — no Evolution, no Kontact. Google Chrome: its apt
repo and signing key are preconfigured, but the `.deb` is **not** baked into the
ISO; the user installs it on first boot or through Discover. The dock keeps its
Chrome slot.

**Bashan app** — a Brave app-mode wrapper: a `.desktop` launching
`--app=https://bashan.app`, owner's logo as icon, its own WM class. No Electron,
no Tauri. The app zip, its source and any keys never enter git or the ISO.

**Viewers / editors** — Okular, Gwenview, Spectacle, Kate, Ark, calculator,
camera app.

**System** — System Settings, Discover with Flatpak/Flathub, KInfoCenter, System
Monitor, KDE Partition Manager, Filelight, CUPS printing setup, Bluetooth setup,
firewall GUI, a snapshot/backup tool, a drivers helper.

**Bashan welcome app** — language, theme, boot-song toggle.

## Open

- Telegram: owner decides at the app stage (Stage 4).

## Measured installed size — Stage 4, 2026-10-12

Cumulative dependency simulation inside the trixie container, recommends ON
(the owner's 1.0 decision). Each group's figure is its **incremental** cost in
the order listed, so shared dependencies are never double counted.

| Group | +Packages | +Size | Running total |
|---|---:|---:|---:|
| base | 192 | 410 MB | 410 MB |
| firmware | 27 | 637 MB | 1048 MB |
| desktop | 1194 | 3213 MB | 4261 MB |
| apps | 217 | 884 MB | 5146 MB |
| browsers (Brave) | 2 | 470 MB | 5616 MB |
| office | 142 | 710 MB | 6327 MB |
| system-tools | 115 | 128 MB | 6456 MB |
| fonts | 5 | 14 MB | 6470 MB |
| i18n | 20 | 62 MB | 6533 MB |
| **Total** | **1914** | | **6533 MB** |

This is uncompressed on-disk size. The ISO squashfs typically compresses
around 3:1, so expect roughly a 2.2 GB image — to be confirmed at Stage 9.

### What recommends cost

| | Packages | Size |
|---|---:|---:|
| Recommends ON (shipping for 1.0) | 1914 | 6533 MB |
| Recommends OFF | 1423 | 4621 MB |
| **Difference** | **491** | **1911 MB** |

### Trim candidates — deferred to post-1.0 by owner decision

All of these are pulled in by Recommends only, so none is required for a
working system. Ranked by size:

| Package | Size | Why it is here | Why it is a candidate |
|---|---:|---|---|
| `fonts-noto-extra` | 326 MB | font recommends | scripts we do not ship |
| `fonts-noto-cjk-extra` | 210 MB | font recommends | Chinese/Japanese/Korean — not a shipped language |
| `openjdk-21-jre-headless` | 194 MB | LibreOffice Base | only Base needs Java; real functional loss if removed |
| `fonts-noto-cjk` | 89 MB | font recommends | as above |
| `fonts-noto-ui-extra` | 70 MB | font recommends | as above |
| `gcc-14-x86-64-linux-gnu` | 67 MB | toolchain recommends | end users do not compile |
| `firmware-marvell-prestera` | 59 MB | `firmware-linux` | datacenter switch ASIC firmware, useless on a laptop |
| `cryfs` | 56 MB | Plasma Vault | encrypted folders, rarely used |
| `git` | 48 MB | recommends chain | developer tool |
| `pocketsphinx-en-us` | 36 MB | recommends chain | offline speech recognition, unused |
| `g++-14-x86-64-linux-gnu` | 36 MB | toolchain recommends | as gcc |

The four CJK/extra Noto font packages alone are **696 MB** for languages
Bashan OS does not ship.

## Background indexers and PIM

**Akonadi: absent.** Choosing Thunderbird over Kontact keeps the entire Akonadi
stack and its MariaDB backend out of the image. Verified: no `akonadi*`,
`mysql*` or `mariadb*` package appears in the resolved set.

**Baloo: present but disabled by default.** Six `baloo*` packages arrive as
dependencies of Plasma and Dolphin and cannot be removed without breaking them.
Baloo's `baloo_file` daemon re-indexes the whole home directory in the
background — minutes of disk thrashing and tens to hundreds of MB resident on
an older laptop. `hooks/rootfs/etc/xdg/baloofilerc` ships with
`Indexing-Enabled=false`, so it never starts. Users who want desktop search can
turn it on in System Settings > Search.

### Other daemons that cost idle RAM

| Daemon | Kept? | Reasoning |
|---|---|---|
| `baloo_file` | **disabled** | see above |
| `packagekit` | keep | Discover needs it; it exits when idle |
| `cups-daemon` | keep | printing |
| `cups-browsed` | **flag** | network printer discovery; a known idle-CPU offender, candidate for disabling |
| `avahi-daemon` | **flag** | mDNS discovery; only needed for network printers/shares |
| `bluez` | keep | Bluetooth |
| `ibus` | keep | required for Arabic/Hebrew/Syriac/Persian input |
| `udisks2`, `upower`, `sddm` | keep | removable media, battery, login |
| `plasma-vault` + `cryfs` | **flag** | encrypted folders, rarely used |

Figures for actual idle RAM require a booted system and come at Stage 9.
