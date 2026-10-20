#!/usr/bin/env python3
"""Replace still-unconfirmed artwork with neutral placeholders, lb tree only.

PLACEHOLDER_ASSETS=yes makes a public build ship plain generated art in place
of anything whose redistribution rights nobody has written down, so an ISO can
be published, and a fork can be built, while those questions are still open.

What this script replaces is now ONE file. The rest is handled elsewhere, or
no longer needs handling at all:

  installer welcome panel   HERE. A composed 880x544 panel of multilingual
                            text. Still unconfirmed.
  mountain wallpaper        scripts/10-lb-config.sh, which fills the default
                            wallpaper package with the ridge art instead. The
                            Arabic wordmark lives in that photograph, so it
                            goes with it.
  Trash icons               scripts/10-lb-config.sh, which drops them so the
                            themes inherit Breeze's own.
  the boot song             config/build.conf: INCLUDE_BOOT_SONG=no.

  the hand logo             NOTHING. 2026-10-20 the owner confirmed the
                            "OK hand" - the Bashan app logo and a Druze
                            community symbol - as Bashan Tech LLC's own mark.
                            It and everything drawn from it (Plymouth, GRUB,
                            SDDM, the installer, the app icons, the avatar,
                            the fastfetch ASCII art and both boot-menu
                            splashes) now ship in public builds as they are.
                            It is proprietary, not open licensed: LICENSE 2b.

It writes into config/includes.chroot inside the live-build tree and never
touches the tracked artwork.

    ./scripts/26-placeholder-art.py <lb-tree>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

INK = (226, 232, 240)      # a plain near-white
SLAB = (30, 41, 59)        # a plain slate, nothing like the Bashan cyan


def backdrop(w: int, h: int) -> Image.Image:
    """A flat vertical gradient. No photograph, no third-party input."""
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)],
               fill=(int(15 + 18 * t), int(23 + 24 * t), int(42 + 34 * t)))
    return im


def font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except OSError:
        return ImageFont.load_default()


def centred(d: ImageDraw.ImageDraw, w: int, h: int, text: str, f) -> None:
    box = d.textbbox((0, 0), text, font=f)
    d.text(((w - box[2] + box[0]) / 2 - box[0],
            (h - box[3] + box[1]) / 2 - box[1]), text, font=f, fill=INK)


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

    n = 0
    # The installer's welcome panel. 880x544 is the size the real one is drawn
    # at; Calamares scales to fill and crops the overflow, so a different
    # aspect ratio loses the edges.
    panel = inc / "usr/share/calamares/branding/bashan/welcome.png"
    if panel.parent.is_dir():
        pw, ph = 880, 544
        im = backdrop(pw, ph)
        d = ImageDraw.Draw(im)
        centred(d, pw, ph, "Bashan OS", font(56))
        im.save(panel, "PNG", optimize=True)
        n += 1

    print(f"I: {n} image(s) replaced with neutral placeholders")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
