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

**Desktop trash icon** — bottom-right for en, es, de, fr, pt, ku (Kurmanji), ru,
el. Bottom-left for ar, he, syr, ckb (Sorani), fa. Placed by a first-login
script that reads the locale and re-runs on locale change.

**Boot / shutdown** — full-screen black splash, large glowing logo, identical on
UEFI and BIOS. An early systemd service plays the boot song through ALSA: it
never blocks boot, fails silently, holds the splash at least 5.5 s, and has an
on/off toggle. Real boot-time impact to be measured and reported.

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
