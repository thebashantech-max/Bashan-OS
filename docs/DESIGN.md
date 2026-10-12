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

## Open

- Trash icon: variant A (faithful to reference, keeps baked-in Arabic text) vs
  variant B (text-free). Owner chooses at Stage 6.
