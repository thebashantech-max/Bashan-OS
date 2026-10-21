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
import os
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

# The photograph itself is local-only - its rights are unconfirmed, so it is
# not in the repository and a clone does not have it. Check it where it
# actually lives if it is present, and say so if it is not. What matters to
# this test is that every declaration AGREES; the build substitutes the ridge
# art when the photo is absent.
src = ROOT / "theme/wallpapers/bashan-mountain-1920x1080.png"
private = pathlib.Path(
    os.environ.get("BASHAN_PRIVATE_ASSETS", pathlib.Path.home() / "bashan-private-assets")
) / "theme/wallpapers/bashan-mountain-1920x1080.png"
if src.is_file():
    print("  the mountain photograph is in the tree")
elif private.is_file():
    print("  the mountain photograph is local-only, found in the private assets")
else:
    print("  the mountain photograph is local-only and not on this machine;")
    print("  the build will substitute the generated ridge art")

print(f"  {checked} wallpaper declarations checked")
if fails:
    print("\nI: wallpaper check FAILED")
    for f in fails:
        print(f"  {f}")
    sys.exit(1)
print(f"I: every wallpaper declaration points at {WANT.split('/')[-4]}")
