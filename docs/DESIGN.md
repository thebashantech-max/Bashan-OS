# Bashan OS — Design System

Navy/black base, cyan accent. Dark, layered, calm. Blur and subtle animation only.

## Status
Stage 6 (logo pipeline and design system) not started. This file records
decisions as they are made and will carry previews and measured idle RAM/CPU
after each design stage.

## Decided

**Wallpaper** — dark layered mountain-ridge, generated procedurally (SVG/Python).
Variants: 4K, 1080p, and a login variant.

**Dock** — floating pill, bottom centre, glass blur, 1px border, small gap to the
screen edge, glowing mint/cyan active indicator. Left-most button is the Bashan
logo launcher with a cyan glow; it mirrors to the right edge in RTL languages.
Pinned order: launcher, Brave, Chrome, Dolphin, Bashan app, Konsole, camera.

**Packaged themes** — Plasma look-and-feel "Bashan", desktop theme, Kvantum,
icon theme "Bashan" (with empty/full trash states), cursor theme, SDDM,
Plymouth, GRUB, Konsole profile, fastfetch. All applied by default via
`/etc/skel`.

**Widgets** — clock, system monitor, weather, media, notes.

**Dock pinned order — exact desktop IDs (verified to exist, Stage 5)**

The leftmost Bashan logo button is a Kickoff launcher *applet*, not a pinned
task, so it is not part of the task manager's `launchers=` list. The pinned
tasks, in order, are:

| # | App | Desktop ID |
|---|---|---|
| 1 | Brave | `brave-browser.desktop` |
| 2 | Google Chrome | `google-chrome.desktop` |
| 3 | Dolphin | `org.kde.dolphin.desktop` |
| 4 | **Bashan app** | `bashan-app.desktop` |
| 5 | Konsole | `org.kde.konsole.desktop` |
| 6 | Camera | `org.kde.kamoso.desktop` |

In RTL locales the whole dock mirrors, putting the logo launcher on the right.

**Open issue — the Chrome slot.** Chrome is deliberately not installed, so
`google-chrome.desktop` does not exist in a fresh image. Plasma silently drops
pinned launchers whose desktop file is missing, so slot 2 will simply not
appear until the user installs Chrome. Two ways to honour "the dock slot
stays", to be decided at Stage 6:
  a. Ship a small `google-chrome.desktop` placeholder that offers to install
     Chrome, and let the real one replace it on install.
  b. Accept the slot appearing only after Chrome is installed.

**Desktop trash icon** — bottom-right for en, es, de, fr, pt, ku (Kurmanji), ru,
el. Bottom-left for ar, he, syr, ckb (Sorani), fa. Placed by a first-login
script that reads the locale and re-runs on locale change.

**Boot / shutdown** — full-screen black splash, large glowing logo, identical on
UEFI and BIOS. An early systemd service plays the boot song through ALSA: it
never blocks boot, fails silently, holds the splash at least 5.5 s, and has an
on/off toggle. Real boot-time impact to be measured and reported.

## Logo source — measured limits (Stage 5)

`assets/branding/logo-source.jpg`, 716x749 progressive JPEG, 29 KB.

| Measurement | Value | Consequence |
|---|---|---|
| Actual artwork extent | **374 x 532 px** | 74% of the file is black padding; the real logo is much smaller than the file suggests |
| Square artwork after crop | 574 x 574 px | 512 px icons are a slight **downscale** — clean |
| Background | pure black (max channel value 1) | alpha can be derived from brightness, which preserves the cyan glow as a soft halo instead of clipping it |
| Chroma subsampling | 4:2:0 | colour detail is half resolution; coloured edges are slightly soft |
| JPEG block artifacts | ratio 1.25 (visible starts ~1.3) | mild, hidden by downscaling |

**Verdict: good up to 512 px, not beyond.** Anything larger is an upscale of
574 px artwork and will look soft. This matters at Stage 7: a full-screen boot
splash logo is fine at 1080p but will be soft at 4K. A higher-resolution or
vector master would fix it.

The artwork is a detailed illustration (skin shading, knuckle creases), not a
flat mark, so it does not vectorise usefully — `potrace` would destroy it. At
16-24 px the detail is unavoidably lost; the generator applies a light unsharp
mask below 48 px to keep the silhouette readable.

## Installer safety — owner requirement, binding on Stage 7

The target machine is the owner's father's laptop, installed from a USB stick,
and it has an existing operating system on it.

1. **No disk is ever wiped without an explicit confirmation screen** that names
   the drive, its size and its current contents in plain language, and requires
   a deliberate action to proceed. "Next" is not enough.
2. **Dual boot must be offered as a first-class choice**, not hidden behind a
   "manual partitioning" expert path. Calamares must run `os-prober`, detect the
   existing OS by name, and present "Install alongside <existing OS>" as a
   visible option.
3. The default highlighted option must never be the destructive one.
4. GRUB must list the existing OS after installation; this is verified at
   Stage 9 in QEMU with a second OS present on the virtual disk.

`os-prober` is already in `packages/base.list.chroot` for this reason.

## Built at Stage 6

Everything below is generated from `theme/palette.json`. Change a colour
there and the wallpaper, colour scheme and dock follow.

| Script | Produces |
|---|---|
| `scripts/21-trash-icons.py` | trash icons, both variants, 8 sizes each |
| `scripts/22-wallpaper.py` | 4K, 1080p and login wallpapers |
| `scripts/23-theme-package.py` | colour scheme, look-and-feel package, icon theme indexes |
| `scripts/24-previews.py` | the approval previews in `build/previews/` |
| `scripts/20-bashan-app-icons.py` | app icon and the glowing launcher icon |

### Palette

Accent `#22d3ee`, hue 189 degrees, **sampled from the cyan glow in
`logo-source.jpg`** (measured mean of cyan-dominant pixels, brightest
decile `#0e737b`), not chosen by eye. Mint `#5eead4` for the dock's active
indicator. 24 tokens in `theme/palette.json`.

### Wallpaper

Fully procedural, no source image and nothing to license. A sky gradient, a
cyan bloom on the horizon, then six ridge layers of 1-D fractal noise.

Two things that matter:
  * **Ridged noise.** Plain fractal noise gives rolling hills. Folding each
    octave around its midpoint gives sharp crests, which is what reads as
    mountains.
  * **Perspective frequency.** A distant range packs many small peaks into
    the same screen width; a near one shows few large ones. Roughness falls
    and amplitude rises as ranges come forward. Doing it the other way round
    looks like waves.

Dithered before the 8-bit save: a dark smooth gradient bands visibly without
it, on exactly the sort of panel this ships to. `SEED` fixes the range, so
rebuilds are identical.

Measured peak memory for the 4K render: **621 MB**.

### Icon theme

`Bashan`, inheriting `breeze-dark`. It overrides only the trash states;
everything else falls through to Breeze. Both trash variants are generated
and `TRASH_VARIANT` in `config/build.conf` picks which one ships.

Extracting the trash art needed three attempts and the reasoning is worth
keeping: the reference's rounded tile is a presentation device, so it is
masked off by its actual rounded-rectangle shape (a uniform inset clips the
glass where it reaches toward an edge). Alpha comes from brightness, which
is what makes glass read as glass. The Arabic text is removed by labelling
every bright shape in the region and erasing only those touching no edge —
the rim and the contents run off an edge and survive, the glyphs float free
and go. A rectangular patch or a per-column rim estimate both destroy the
rim.

### Dock

A floating pill, centred, `lengthMode = fit`, 60 px tall, 18 px clear of the
screen edge. Plasma 6 draws the blur and 1 px border once `floating` is on.
Every plasmoid id in the layout was read out of the Debian packages that
ship them, not guessed.

**One decision taken, flagged for approval:** the brief lists only the seven
pinned items, but a laptop needs battery, wi-fi, volume and bluetooth
indicators somewhere. Rather than add a second panel (more RAM, more
clutter), the system tray and a compact clock sit at the right end of the
same pill, behind a divider. Say the word and they move.

### Chrome placeholder

`/usr/share/applications/google-chrome.desktop` is shipped as a placeholder
whose `Exec` is `/usr/bin/bashan-install-chrome`. That script asks for
confirmation in plain words, states the download size and that a password
will be needed, runs the install through `pkexec`, and reports success or a
plain-language failure. The root half deletes the placeholder immediately
before `apt-get install`, so the real Chrome entry lands on the same path
and the same dock pin with no handover step and no dpkg file conflict.

Needs `kdialog`, `pkexec` and `polkit-kde-agent-1`, all added to the
system-tools list. Without the polkit agent there is no graphical password
prompt at all.

## Leftover theme pieces — Stage 7A

| Piece | Status |
|---|---|
| Konsole profile + colour scheme | **done**, generated from the palette, set as default via `/etc/skel/.config/konsolerc` |
| fastfetch config | **done**, with an ASCII logo derived from the source artwork |
| Cursor theme | **done as an alias only** — `Bashan` inherits `breeze_cursors`. Real cursor art means ~40 hand-drawn shapes plus animation frames; declaring the theme now means the name is in place if art arrives later |
| Plasma desktop theme | **done, minimal.** Plasma falls back per file, so the theme ships only `widgets/panel-background.svg` (the dock pill, nine-sliced) plus colours, and inherits Breeze for everything else |
| Kvantum theme | **not done — see below** |

### Why Kvantum was dropped for 1.0

Every Kvantum theme in Debian ships a `.kvconfig` *and* a `.svg`; there is
no config-only form. That SVG carries hand-drawn nine-slice artwork for
every widget state — buttons, entries, tabs, scrollbars, menus — which runs
to hundreds of named elements. Three options:

1. Draw it. Real design work, days, not something to fake.
2. Copy a GPL Kvantum theme's SVG and recolour it. Workable, but it puts
   GPL artwork into a commercial product and brings licence obligations.
3. Skip it. Breeze with the Bashan colour scheme and accent already themes
   Qt applications consistently, and Plasma 6's Breeze honours our accent.

Option 3 for 1.0, and the Kvantum engine is **not** installed, since
shipping a style engine nothing uses is exactly the bloat this project is
avoiding. Revisit when there is artwork.

## Open

- Trash icon: variant A (faithful to reference, keeps baked-in Arabic text) vs
  variant B (text-free). Owner chooses at Stage 6.
