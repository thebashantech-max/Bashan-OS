#!/usr/bin/env python3
"""Generate the boot-chain artwork: Plymouth, GRUB and SDDM.

Logo sharpness
--------------
The source artwork is 574 px square (see docs/DESIGN.md). Rather than scale
the logo to a fixed fraction of the screen - which would upscale it on a 4K
panel and look soft - the Plymouth script caps it at native size:

    logo height = min(0.28 * screen_height, 574)

so the logo is only ever scaled DOWN, never up, and stays crisp at every
resolution. The trade is that on a 4K panel it occupies 26.6% of the screen
height instead of 28%, which is not a visible difference.
"""
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
PAL = json.loads((ROOT / "theme/palette.json").read_text())
SRC = ROOT / "assets/branding/logo-source.jpg"
BRAND = ROOT / "branding"
# The glow padding (x1.42) is part of the image, so the asset is larger than
# the artwork inside it. Native artwork is 574 px, hence a native padded
# image of 815 px, and a target fraction of 0.28 * 1.42 to put the ARTWORK
# at 28% of screen height. These three constants are mirrored in
# branding/plymouth/bashan/bashan.script - keep them in step.
GLOW_PAD = 1.42
NATIVE_CAP = 815
ART_FRACTION = 0.28
IMAGE_FRACTION = 0.40
LOGO_SIZES = (256, 384, 512, 640, 815)


def c(tok):
    h = PAL[tok].lstrip("#")[:6]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def logo_rgba() -> Image.Image:
    """The logo with alpha from brightness and a cyan bloom behind it."""
    import numpy as np
    a = np.asarray(Image.open(SRC).convert("RGB"))
    lum = a.max(axis=2)
    ys, xs = np.nonzero(lum > 8)
    pad = int(round(max(xs.ptp(), ys.ptp()) * 0.04))
    x0, y0 = max(0, xs.min() - pad), max(0, ys.min() - pad)
    x1, y1 = min(a.shape[1] - 1, xs.max() + pad), min(a.shape[0] - 1, ys.max() + pad)
    rgb = a[y0:y1 + 1, x0:x1 + 1]
    alpha = np.clip((lum[y0:y1 + 1, x0:x1 + 1].astype("float32") - 6) * 3.0, 0, 255)
    art = Image.fromarray(np.dstack([rgb, alpha]).astype("uint8"), "RGBA")
    # Pad generously BEFORE blurring. Without the margin the halo is cut off
    # at the canvas edge and the "glow" renders as a hard cyan square.
    side = int(max(art.size) * GLOW_PAD)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(art, ((side - art.width) // 2, (side - art.height) // 2))

    halo = sq.getchannel("A").filter(ImageFilter.GaussianBlur(int(side * 0.055)))
    halo = ImageChops.multiply(halo, Image.new("L", sq.size, 190))
    glow = Image.new("RGBA", sq.size, c("accent") + (0,))
    glow.putalpha(halo)
    out = Image.alpha_composite(glow, glow)
    return Image.alpha_composite(out, sq)


def scene(w: int, h: int, darken: float) -> Image.Image:
    """The ridge wallpaper, darkened, for GRUB and SDDM backgrounds."""
    src = ROOT / "theme/wallpapers/bashan-ridge-3840x2160.png"
    im = Image.open(src).convert("RGB").resize((w, h), Image.LANCZOS)
    return ImageChops.multiply(im, Image.new("RGB", (w, h),
                                             tuple(int(255 * darken) for _ in range(3))))


def main() -> None:
    art = logo_rgba()
    print(f"I: logo artwork {art.size[0]}px native (cap {NATIVE_CAP}px)")

    # ---- Plymouth -------------------------------------------------------
    pl = BRAND / "plymouth/bashan"
    pl.mkdir(parents=True, exist_ok=True)
    for s in LOGO_SIZES:
        art.resize((s, s), Image.LANCZOS).save(pl / f"logo-{s}.png", optimize=True)
    print(f"   plymouth logos: {', '.join(str(s) for s in LOGO_SIZES)} px")

    # A 1 px tall gradient strip Plymouth stretches to fill the screen, so
    # the background costs nothing regardless of panel resolution.
    strip = Image.new("RGB", (1, 256))
    d = ImageDraw.Draw(strip)
    top, bot = c("sky_top"), c("bg_void")
    for y in range(256):
        t = y / 255
        d.point((0, y), tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(3)))
    strip.save(pl / "background.png")

    # ---- GRUB -----------------------------------------------------------
    gr = BRAND / "grub/bashan"
    gr.mkdir(parents=True, exist_ok=True)
    scene(1920, 1080, 0.55).save(gr / "background.png", optimize=True)
    art.resize((180, 180), Image.LANCZOS).save(gr / "logo.png", optimize=True)
    print("   grub: background.png, logo.png")

    # ---- SDDM -----------------------------------------------------------
    sd = BRAND / "sddm/bashan"
    sd.mkdir(parents=True, exist_ok=True)
    Image.open(ROOT / "theme/wallpapers/bashan-ridge-login-1920x1080.png").save(
        sd / "background.png", optimize=True)
    art.resize((160, 160), Image.LANCZOS).save(sd / "logo.png", optimize=True)
    print("   sddm: background.png, logo.png")

    # ---- report the scaling behaviour ------------------------------------
    print("\n   Plymouth logo, by panel (artwork size excludes the glow halo):")
    for name, h in (("1366x768", 768), ("1920x1080", 1080),
                    ("2560x1440", 1440), ("3840x2160", 2160)):
        img = min(h * IMAGE_FRACTION, NATIVE_CAP)
        artpx = img / GLOW_PAD
        pick = min((s for s in LOGO_SIZES if s >= img), default=LOGO_SIZES[-1])
        how = "downscaled" if pick > img else "native, no scaling"
        print(f"     {name:<10} artwork {artpx:4.0f}px ({100 * artpx / h:4.1f}% of "
              f"height) from the {pick}px asset - {how}")


if __name__ == "__main__":
    main()
