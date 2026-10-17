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

**Desktop Trash** — a Trash **plasmoid**, placed by Plasma wherever it
decides. **Its position cannot be set**, and no corner is promised.

This was meant to be bottom-right for the eight left-to-right languages and
bottom-left for the five right-to-left ones. That proved impossible, and the
attempts are worth recording so nobody repeats them:

* Folder View, Plasma 6's default desktop, has **no applet position system
  at all** - it never imports `ContainmentLayoutManager.AppletsLayout`.
* The Desktop containment does use that system, but assigned geometry is
  accepted and silently ignored; Plasma arranges applets itself.
* `Qt.rect()` does not exist in Plasma's scripting environment
  (`ReferenceError: Qt is not defined`), and a plain `{x,y,width,height}`
  object raises no error and has no effect.
* The containment type is read-only from the scripting API.

A static `Type=Link` desktop icon **can** be put in a corner, but it draws
whatever its `Icon=` field names, so it shows the EMPTY bin forever - tested
with a real trash entry, before and after a forced refresh. A Trash icon
that never fills looks broken.

The plasmoid was chosen because it shows the approved variant-B glass
artwork in **both** states and switches by itself. The user can drag it once
and Plasma remembers.

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

## Part B — the light variant (2026-10-12)

**Dark remains the default.** Nothing about the dark theme changed: the dark
wallpapers and the dark launcher icon regenerate byte-identical, which was
checked with `git status` after the refactor rather than assumed.

### How it is built

`theme/palette-light.json` carries **the same 37 token names** as
`theme/palette.json`. Roles are preserved, not colours — `bg_deep` is the
text-entry surface in both files (near-black in dark, white in light), and
`bg_void` is the strongest-contrast surface in both. Because the token names
match, every generator reads either file with no special case, and the
variant loop is three lines in each.

`scripts/_palette.py` is the shared loader. It exposes the two variants with
their Plasma names (`Bashan` / `BashanLight`, `com.bashan.desktop` /
`com.bashan.desktop.light`) and the filename suffix.

Four constants that used to be hardcoded in the wallpaper renderer are now
palette tokens (`wall_glow`, `wall_vignette`, `wall_login_dim`, `wall_rim`,
plus `wall_glow_rgb`), and three more drive the dock pill (`dock_fill`,
`dock_stroke`, `dock_opacity`). The light scene is therefore a palette
change, not a branch in the renderer.

### What is generated per variant

| Artefact | Dark | Light |
|---|---|---|
| Colour scheme | `Bashan.colors` | `BashanLight.colors` |
| Look-and-feel | `com.bashan.desktop` | `com.bashan.desktop.light` |
| Desktop theme | `Bashan` | `Bashan-Light` |
| Wallpaper 4K / 1080p / login | `bashan-ridge-*` | `bashan-ridge-light-*` |
| Icon theme | `Bashan` | `Bashan-Light` |
| Launcher glow | bright cyan, strength 0.78 | dark cyan `#0e7490`, strength 0.42 |

### The accent could not be reused

The dark accent `#22d3ee` measures **1.65:1 on white** and is unreadable as
text. The light accent is the same hue darkened to `#0e7490`, which measures
**4.99:1** on the light window background. `scripts/_palette.py` enforces
eleven contrast rules across both variants and runs as part of
`./build.sh test`, so a future palette edit cannot quietly undo this.

### Switching

Two mechanisms, neither of which is custom UI:

1. **System Settings → Global Theme** lists "Bashan" and "Bashan Light",
   because both look-and-feel packages ship. No code of ours is involved.
2. **`bashan-theme-toggle`**, also in the launcher as "Dark / Light Theme".

The toggle deliberately does **not** apply a look-and-feel package. Applying
one re-runs its layout script, which rebuilds the dock and discards any
widget the user has added or moved. Instead it switches the four pieces
separately — colour scheme, desktop theme, wallpaper, icon theme — using
`plasma-apply-colorscheme`, `plasma-apply-desktoptheme`,
`plasma-apply-wallpaperimage` and `plasma-changeicons`, all of which ship in
`plasma-workspace` and were verified present in the built image.

The launcher glow swaps because `Bashan-Light` contains different artwork
under **the same icon name**, so changing the icon theme changes the dock
button without touching the dock's applet configuration.

Automatic day/night switching is **off by default** — see
`docs/THEME-DAYNIGHT.md`.

### Honest assessment: how hard, and what looks worse

**Difficulty: moderate, and almost all of it was colour judgement rather
than code.** The mechanical part — two palettes, a shared loader, variant
loops in four generators — took four small patches and no new concepts. The
dark output being byte-identical afterwards is the evidence that it was a
clean refactor. What actually took the work was that a dark palette cannot
be inverted into a light one. Three things had to be rethought from scratch:

1. **The accent.** Covered above. It had to be re-derived, not flipped.
2. **The horizon glow.** The wallpaper's cyan bloom is *additive*. Adding a
   pale cyan to a pale sky clips to white and the brand cue disappears
   entirely — the first light wallpaper had no cyan in it at all. The fix
   was to give the wallpaper its own `wall_glow_rgb` token so the light
   scene can use a saturated cyan where the light UI uses a pale one.
3. **The dock pill.** A pale translucent pill with a pale border on a pale
   wallpaper has no edge. Light needs higher opacity (0.66 vs 0.55) and a
   darker border.

**What genuinely looks worse in light, in order:**

1. **The Trash icons.** The glass artwork was cut from your reference image,
   which is lit for a dark background. On the light wallpaper it reads as
   washed-out grey rather than glass. This is the weakest element in light
   and cannot be fixed by palette alone — it needs a light-tuned re-cut of
   the two icons. Not done; say the word.
2. **The active-app indicator.** A glowing mint pill under a running app is
   a *glow*, and a glow needs darkness around it. On light it degrades from
   "glowing" to "a coloured dot". Still legible, no longer a signature.
3. **The launcher mark.** Your logo is a lit hand painted on black. Its
   halo cannot glow against white — the darker light-mode glow restores an
   outline, but the premium lit quality is a property of the dark theme.
4. **The active-window frame.** `accent_deep` in light is a pale cyan, so
   the focused-window border is subtler than in dark. Comparable to stock
   Breeze Light; acceptable, but it is a downgrade.

Items 1-3 are all the same underlying fact: this identity is built on
luminous marks against darkness, and light mode removes the darkness. The
light theme is clean, readable and consistent, and it is not as distinctive
as the dark one. Dark is the right default.

### Not verified

The toggle has never been run — nothing has started Plasma since it was
written. The previews are mockups drawn from the real palette, real
wallpapers and real generated icons, not screenshots. Both get exercised in
Part G.
