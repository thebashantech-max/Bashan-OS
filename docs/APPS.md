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

**Bashan app** — a Brave app-mode wrapper. No Electron, no Tauri, no extra
runtime: it is one `.desktop` file plus nine PNG icons, and it reuses the Brave
that is already installed. The app zip, its source and any keys never enter git
or the ISO (`assets/apps/` is gitignored and nothing reads it).

Built at Stage 5:

| File | Purpose |
|---|---|
| `apps/rootfs/usr/share/applications/bashan-app.desktop` | the launcher |
| `apps/rootfs/usr/share/icons/hicolor/<size>/apps/bashan-app.png` | 9 sizes, 16-512 px |
| `scripts/20-bashan-app-icons.py` | regenerates the icons from the source logo |

```
Exec=/usr/bin/brave-browser-stable --app=https://bashan.app --class=bashan-app
StartupWMClass=bashan-app
```

**The binary is `brave-browser-stable`.** Brave's deb ships no
`/usr/bin/brave-browser` symlink; verified by unpacking the 1.97.56 package.
Using the shorter name would have produced a launcher that silently does
nothing.

**`--class=bashan-app`** gives the window its own `WM_CLASS`. Brave's own class
is `brave-browser`, so without this the Bashan app would be grouped under
Brave's dock icon instead of getting its own. Still to verify with `xprop` in a
real session at Stage 9: that Chromium applies the class exactly as given.

No `--user-data-dir`: the app shares the normal Brave profile, so the user
stays signed in and there is no second browser profile on disk.

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

## Part A additions — viewers, converters, editors (2026-10-12)

Every package name below was resolved against the **real trixie archive**,
and every size is the **true marginal cost** measured by simulating the
install against the already-built 7.6 GB chroot — not a guess from the
package's own size.

| Package | trixie version | Added, installed | New pkgs |
|---|---|---|---|
| `vlc` | 3.0.24-0+deb13u1 | **63.2 MB** | 12 |
| `gimp` | 3.0.4-3+deb13u11 | **131.4 MB** | 19 |
| `kdenlive` | 24.12.3-2+deb13u1 | **291.6 MB** | 85 |
| `kolourpaint` | 4:25.04.0-1 | **11.1 MB** | 4 |
| `converseen` | 0.14.0.0-1 | **2.2 MB** | 2 |
| `handbrake` | 1.9.2+ds1-1 | **43.9 MB** | 7 |
| **total** | | **543.5 MB** | **129** |

Converseen and HandBrake both exist in trixie, so neither fallback was
needed. Gwenview and Okular were already installed in Stage 4.

### Image and video formats cost nothing

HEIC, AVIF, JPEG XL, WebP, TIFF and camera RAW are **already supported** by
packages installed in Stage 4, so no package was added for any of them:

| Format | Provided by | Already installed |
|---|---|---|
| HEIC / HEIF | `kimg_heif.so` (kimageformat6-plugins) | yes |
| AVIF | `kimg_avif.so` | yes |
| JPEG XL | `kimg_jxl.so` | yes |
| WebP | `libqwebp.so` (qt6-image-formats-plugins) | yes |
| TIFF | `libqtiff.so` | yes |
| Camera RAW | `kimg_raw.so` + `rawthumbnail.so` | yes |

Audio/video codecs likewise: `gstreamer1.0-plugins-{good,bad,ugly}` and
`gstreamer1.0-libav` were already installed, and `vlc` brings
`vlc-plugin-base`. `libavcodec-extra` (16.3 MB) was **not** added — it would
swap out `libavcodec61` for the extra-codecs build for a small gain in rare
formats, and it widens the patent surface. It remains one apt command away.

### RAW: what actually works, and what does not

- **Viewing and thumbnailing RAW works.** `kimg_raw.so` is a Qt image
  plugin, so Gwenview opens RAW at full size, and
  `kdegraphics-thumbnailers` gives Dolphin RAW thumbnails. Both verified
  present as files; neither has been exercised on a real `.cr2`/`.nef` yet.
- **Editing RAW in GIMP does not work out of the box.** GIMP has no RAW
  loader of its own — it hands RAW files to darktable or RawTherapee, and
  neither is installed. Installing one costs roughly 100-200 MB. Not added:
  it was not requested, and it is one click away in Discover.

### Default applications

`/etc/xdg/mimeapps.list` (87 associations): photos open in **Gwenview**,
video and audio in **VLC**, PDFs in **Okular**, `.xcf`/`.psd` in **GIMP**,
text in Kate, archives in Ark.

This is checked, not assumed. `scripts/52-check-defaults.sh` validates every
`.desktop` id against the files the installed system will really have, and
every MIME name against trixie's `shared-mime-info`. It is worth running
because a wrong name in `mimeapps.list` **fails silently** — the association
is ignored and the file opens in whatever app wins by chance.

It caught three real defects when first run:

1. `image/x-psd` was pointed at Gwenview while its canonical name
   `image/vnd.adobe.photoshop` was pointed at GIMP — the same format
   assigned to two apps.
2. `image/x-webp` is not a MIME type in trixie at all, despite Gwenview's
   own `.desktop` declaring it. A dead line.
3. Six more entries (`audio/opus`, `audio/x-wav`, `video/avi`,
   `video/x-ms-asf`, `application/x-cb{z,r}`) were aliases rather than
   canonical names.

One alias is kept deliberately: `image/heic`, because that is the name phone
cameras produce.

### Phoning home — measured, not assumed

Each shipped binary was scanned for update/telemetry URLs.

| App | Finding | Action |
|---|---|---|
| **GIMP** | contains `https://www.gimp.org/gimp_versions.json` and checks it for new releases | `(check-update no)` in `/etc/skel/.config/GIMP/3.0/gimprc` |
| **Converseen** | contains `https://converseen.fasterland.net/update/` and `https://fasterland.net/software-updates/converseen-version.txt` | best-effort off in `/etc/skel/.config/Faster/Converseen.conf` — **see the caveat below** |
| **VLC** | no update URL (Debian builds the notifier out). Its album-art lookup is the only outbound call | `qt-privacy-ask=0` + `metadata-network-access=0` in `/etc/skel/.config/vlc/vlcrc`; also suppresses the first-run network dialog |
| **Kdenlive** | no update or telemetry URL found | KUserFeedback pinned to 0 system-wide |
| **KolourPaint** | no update or telemetry URL found | none needed |
| **HandBrake** | no update or telemetry URL found in the shipped files | none needed |

None of the six requires an account, sign-up, login or payment, and all six
are free software in Debian main.

**Caveat on Converseen:** the two setting keys (`checkCheckUpdates`,
`DialogShowUpdateMsg`) were read out of the binary, not confirmed by running
Converseen and reading the file it writes. If a startup version check still
happens, the fix is to read `~/.config/Faster/Converseen.conf` after first
run and correct the key names. This is flagged rather than claimed.

### Idle RAM

**None of the six adds an idle cost.** All are user-launched applications
with no daemon, no autostart entry and no background indexer. Verified by
the absence of any `.service`, `systemd/user` or `autostart` file in the six
`.deb`s. The only idle effect is a slightly larger icon/MIME cache.

### Deliberately excluded

`krita`, `obs-studio` and `audacity` all resolve in trixie and are all one
click away in Discover. Keeping them out of the ISO is the single biggest
size saving available in this part.

### Not done

Nothing was pinned to the dock, as instructed.

---

## Build 17 additions

Everything below is free software with no account, no sign-up, and nothing
that contacts the internet by itself. Sizes are each package's own
Installed-Size; dependencies are extra and appear in the ISO delta.

### Learn to Code

| Tool | Size | Licence | Talks to the internet on its own |
|---|---|---|---|
| Thonny | 7.9 MB | MIT | no |
| KTurtle | 6.0 MB | GPL-2 | no |
| Geany | 4.8 MB | GPL-2 | no |
| IDLE (`idle-python3.13`) | 1.9 MB | PSF | no |
| GCompris (`gcompris-qt` + data) | 78 MB | AGPL-3 | no |

**There is no Scratch-style block-programming tool in Debian 13.** `scratch`,
`scratch3`, `turtleart`, `blockly` and `snap-gui` are all absent from the
archive. None is shipped and none is imitated. KTurtle is the closest
teaching language that actually exists here.

These appear together under **Learn to Code** in the launcher.

### Graphics

| Tool | Size | Licence | Talks to the internet on its own |
|---|---|---|---|
| Krita | 88 MB | GPL-3 | no |
| Inkscape | 108 MB | GPL-3 | **not shipped** — offered as a download |

Krita reuses the Qt and KF6 libraries Plasma already needs, so its real cost
is close to its own size. Inkscape would bring a GTK stack nothing else in
the image uses, which together with its own 108 MB goes past the size budget
for a USB stick that is already slow to read. It is offered through
**Get Inkscape (downloads after you agree)**, the same pattern as Chrome,
and comes from Debian's own archive — no new software source is added.

### Chinese input

`ibus-libpinyin` (2.6 MB, LGPL-2.1) with `fonts-noto-cjk`, already present.
Chinese is an input method, not a keyboard layout, so it does not use one of
the four layout slots.

### Mount Bashan School

A menu entry that opens `https://www.mountbashanschool.org` in its own
window using Brave's app mode, with its own window class so it groups under
its own icon. With no internet it shows a local page saying so in one
sentence, instead of a browser error about DNS. The icon is a generic
education icon, not a copied logo.

---

## Build 17b additions

Sizes are the **real** cost: the dependency closure counting only packages
not already in the image, not each package's own size. All free software,
no account, no sign-up, none contacts the internet by itself.

### Make Games

| Tool | Debian 13 version | Real size | Licence | In the ISO |
|---|---|---|---|---|
| Godot | **godot3 3.6+ds-2** | 75.9 MB | MIT | yes |
| Tiled | 1.11.90-1 | 14.0 MB | GPL-2 | yes |
| LMMS | 1.2.2+dfsg1-6 | 46.4 MB | GPL-2 | yes |
| Pygame | python3-pygame 2.6.1 | 33.4 MB | LGPL-2.1 | yes, under Learn to Code |

**Godot 4 is not in Debian 13.** Only `godot3` (3.6) exists; there is no
`godot4` package at all. Current Godot tutorials target 4.x, so someone
following one will meet differences. 3.6 ships because it works and comes
from Debian. Godot 4 was **not** pulled from outside Debian — that needs
approval first.

### Offered as downloads, not shipped

| Tool | Debian 13 version | Real size | Licence | Why not shipped |
|---|---|---|---|---|
| Blender | 4.3.2+dfsg-2 | **365.9 MB** | GPL-3 | alone it exceeds the whole budget |
| Inkscape | 1.4-6 | 122.4 MB | GPL-3 | GTK stack nothing else needs |
| Audacity | 3.7.3+dfsg-1 | 68.4 MB | GPL-3 | over the remaining budget |

All three install through **Get … (downloads after you agree)**, from
Debian's own archive. No new software source is ever added.

### Files that survive package updates

Six files in this image replace files owned by Debian packages. Without
protection, apt would silently restore the originals on the next upgrade.
All six are now `dpkg-divert`ed:

| File | Owning package | What it would have undone |
|---|---|---|
| `…/lockscreen/LockScreenUi.qml` | plasma-desktop-data | lock screen with no way to shut down |
| `/usr/lib/os-release` | base-files | the OS would call itself Debian again |
| `/usr/share/plymouth/debian-logo.png` | plymouth | Debian logo at boot |
| `/usr/share/pixmaps/debian-logo.png` | debconf | Debian logo in dialogs |
| `/etc/xdg/autostart/im-launch.desktop` | im-config | input-method autostart |
| `…/org.kde.discover.notifier.desktop` | plasma-discover | update notifier re-enabled |

The list came from checking every file we ship against every package's file
list, which is how `os-release` turned up — it had been overwritten, not
diverted, and a routine `base-files` upgrade would have reverted the OS
name itself.
