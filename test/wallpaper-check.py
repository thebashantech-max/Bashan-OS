#!/usr/bin/env python3
"""Every place that decides the wallpaper must name the same file.

Changing the look-and-feel `defaults` was not enough: the layout script
writes the wallpaper directly into the desktop containment at first login
and silently wins, so build 16 booted with the old ridge still on screen
while every config file claimed otherwise.

There are four deciders, and they disagree easily:
  layouts/*.js          what the desktop actually gets at first login
  contents/defaults     [Wallpaper] and the lock screen, per look-and-feel
  kscreenlockerrc       the lock screen on the installed system
"""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
WANT = "/usr/share/wallpapers/BashanMountain/contents/images/1920x1080.png"
fails, checked = [], 0

for variant in ("com.bashan.desktop", "com.bashan.desktop.light"):
    base = ROOT / "theme/look-and-feel" / variant / "contents"
    js = base / "layouts/org.kde.plasma.desktop-layout.js"
    m = re.search(r'(?m)^var wallpaper = "([^"]*)";', js.read_text())
    if not m:
        fails.append(f"{variant}: layout declares no wallpaper")
    elif m.group(1) != WANT:
        fails.append(f"{variant}: layout uses {m.group(1)}")
    checked += 1

    for line in (base / "defaults").read_text().splitlines():
        if line.startswith("Image="):
            checked += 1
            if line[6:] != WANT:
                fails.append(f"{variant}: defaults has {line[6:]}")

for line in (ROOT / "hooks/rootfs/etc/xdg/kscreenlockerrc").read_text().splitlines():
    if line.startswith("Image="):
        checked += 1
        if line[6:] != WANT:
            fails.append(f"kscreenlockerrc has {line[6:]}")

# And the file itself has to exist, at the size its name claims.
src = ROOT / "theme/wallpapers/bashan-mountain-1920x1080.png"
if not src.is_file():
    fails.append(f"missing {src.relative_to(ROOT)}")

print(f"  {checked} wallpaper declarations checked")
if fails:
    print("\nI: wallpaper check FAILED")
    for f in fails:
        print(f"  {f}")
    sys.exit(1)
print(f"I: every wallpaper declaration points at {WANT.split('/')[-4]}")
