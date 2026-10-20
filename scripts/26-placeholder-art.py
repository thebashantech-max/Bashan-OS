#!/usr/bin/env python3
"""Replace unconfirmed artwork with neutral placeholders, in the lb tree only.

Everything branded in this project descends from three files whose origin
nobody wrote down: assets/branding/logo-source.jpg, assets/reference/
trash-icons.jpg and the mountain wallpaper. See LICENSE section 2b.

PLACEHOLDER_ASSETS=yes makes the build ship a plain generated mark and a
generated background instead, so an ISO can be published, and a fork can be
built, while the rights question is still open.

It writes into config/includes.chroot inside the live-build tree and never
touches the tracked artwork. The ridge wallpaper is NOT replaced: that one
is drawn from code by scripts/22-wallpaper.py and is ours outright.

    ./scripts/26-placeholder-art.py <lb-tree>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

INK = (226, 232, 240)      # a plain near-white
SLAB = (30, 41, 59)        # a plain slate, nothing like the Bashan cyan
EDGE = (71, 85, 105)


def mark(size: int) -> Image.Image:
    """A plain rounded slab with a B. Deliberately dull: it must not read as
    a logo anyone could mistake for Bashan's."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pad = max(1, size // 10)
    r = max(2, size // 6)
    d.rounded_rectangle([pad, pad, size - pad, size - pad], radius=r,
                        fill=SLAB, outline=EDGE, width=max(1, size // 32))
    # A letter, only when there are enough pixels for it to be legible.
    if size >= 32:
        try:
            f = ImageFont.truetype(
                "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                int(size * 0.5))
        except OSError:
            f = ImageFont.load_default()
        box = d.textbbox((0, 0), "B", font=f)
        d.text(((size - box[2] + box[0]) / 2 - box[0],
                (size - box[3] + box[1]) / 2 - box[1]), "B", font=f, fill=INK)
    return im


def backdrop(w: int, h: int) -> Image.Image:
    """A flat vertical gradient. No photograph, no third-party input."""
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)],
               fill=(int(15 + 18 * t), int(23 + 24 * t), int(42 + 34 * t)))
    return im


def put_mark(path: Path, size: int) -> bool:
    if not path.parent.is_dir():
        return False
    mark(size).save(path, "PNG", optimize=True)
    return True


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    tree = Path(sys.argv[1])
    inc = tree / "config/includes.chroot"
    if not inc.is_dir():
        print(f"E: {inc} is not there; run this after the includes are built",
              file=sys.stderr)
        return 1

    share = inc / "usr/share"
    n = 0

    # Every logo the boot chain and the installer show.
    for p, s in [
        *[(share / f"plymouth/themes/bashan/logo-{s}.png", s)
          for s in (256, 384, 512, 640, 815)],
        (inc / "boot/grub/themes/bashan/logo.png", 180),
        (share / "sddm/themes/bashan/logo.png", 160),
        (share / "calamares/branding/bashan/logo.png", 160),
        (share / "calamares/branding/bashan/welcome.png", 300),
        (share / "bashan/default-face.png", 256),
    ]:
        n += put_mark(p, s)

    # The app icons, at whatever sizes the themes actually carry. The Bashan
    # icon themes carry their own copy of the launcher, so they count too.
    icon_dirs = list((share / "icons/hicolor").glob("*/apps"))
    for theme in share.glob("icons/Bashan*"):
        icon_dirs += list(theme.glob("*/apps"))
    for d in icon_dirs:
        try:
            s = int(d.parent.name.split("x")[0])
        except ValueError:
            continue
        for f in d.glob("*.png"):
            n += put_mark(f, s)

    # Backgrounds built from the logo artwork or from the mountain photo.
    for p, w, h in [
        (share / "plymouth/themes/bashan/background.png", 1920, 1080),
        (inc / "boot/grub/themes/bashan/background.png", 1920, 1080),
        (share / "sddm/themes/bashan/background.png", 1920, 1080),
        (share / "calamares/branding/bashan/slide-bg.png", 1024, 640),
        (share / "calamares/branding/bashan/banner.png", 1024, 128),
    ]:
        if p.parent.is_dir():
            backdrop(w, h).save(p, "PNG", optimize=True)
            n += 1

    # fastfetch prints an ASCII rendering of the hand logo in every terminal.
    # It is text, so the image sweep above walks straight past it - it reached
    # a finished public ISO once before this was noticed.
    ascii_logo = share / "bashan/logo-ascii.txt"
    if ascii_logo.parent.is_dir():
        ascii_logo.write_text(
            "\n".join(["", "   ####### ", "   ##    ##", "   ####### ",
                        "   ##    ##", "   ####### ", ""]) + "\n")
        n += 1

    # The ISO boot menu splashes, which are committed by hand and unexplained.
    for p, w, h in [(tree / "config/bootloaders/isolinux/splash.png", 640, 480),
                    (tree / "config/bootloaders/grub-pc/splash.png", 1920, 1080)]:
        if p.parent.is_dir():
            backdrop(w, h).save(p, "PNG", optimize=True)
            n += 1

    print(f"I: {n} branded image(s) replaced with neutral placeholders")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
