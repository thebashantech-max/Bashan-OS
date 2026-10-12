#!/usr/bin/env python3
"""Generate the Bashan app icon set from the owner's source logo.

Runs on the host (needs Pillow). Idempotent: rewrites every size each run.

The source is a JPEG of a glowing hand on a solid black field. Two things
follow from that:
  * 74% of the canvas is padding, so we crop to the actual artwork first,
    otherwise the hand renders as a speck in the dock.
  * JPEG has no alpha. The background is pure black and the cyan glow fades
    into it, so we derive alpha from brightness. That keeps the glow as a
    soft halo instead of clipping it to a hard edge.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/branding/logo-source.jpg"
OUT = ROOT / "apps/rootfs/usr/share/icons/hicolor"
NAME = "bashan-app"
LAUNCHER = "bashan-launcher"
SIZES = (16, 22, 24, 32, 48, 64, 128, 256, 512)
# Extra cyan bloom behind the dock launcher button, from the palette accent.
GLOW_RGB = (34, 211, 238)
GLOW_RADIUS = 0.10
GLOW_STRENGTH = 1.0
GLOW_PASSES = 3

# Below this brightness a pixel is background, not artwork.
CONTENT_THRESHOLD = 8
# Brightness -> alpha gain. 3.0 makes the glow solid enough to read while
# leaving the faintest outer falloff translucent.
ALPHA_GAIN = 3.0
ALPHA_FLOOR = 6
# Breathing room around the artwork, as a fraction of its longest side.
MARGIN = 0.04


def build_rgba(src: Path) -> Image.Image:
    im = Image.open(src).convert("RGB")
    a = np.asarray(im)
    lum = a.max(axis=2)

    ys, xs = np.nonzero(lum > CONTENT_THRESHOLD)
    if len(xs) == 0:
        sys.exit(f"E: {src} appears to be blank")
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()

    pad = int(round(max(x1 - x0, y1 - y0) * MARGIN))
    x0, y0 = max(0, x0 - pad), max(0, y0 - pad)
    x1, y1 = min(a.shape[1] - 1, x1 + pad), min(a.shape[0] - 1, y1 + pad)

    rgb = a[y0:y1 + 1, x0:x1 + 1]
    lum = lum[y0:y1 + 1, x0:x1 + 1].astype(np.float32)
    alpha = np.clip((lum - ALPHA_FLOOR) * ALPHA_GAIN, 0, 255).astype(np.uint8)

    art = Image.fromarray(np.dstack([rgb, alpha]), "RGBA")

    # Square canvas so every icon size keeps the same proportions.
    side = max(art.size)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(art, ((side - art.width) // 2, (side - art.height) // 2))
    return canvas


def add_glow(art: Image.Image) -> Image.Image:
    """Cyan bloom behind the mark, for the dock launcher button."""
    side = art.size[0]
    halo = art.getchannel("A").filter(
        ImageFilter.GaussianBlur(max(1, int(side * GLOW_RADIUS))))
    if GLOW_STRENGTH < 1.0:
        halo = ImageChops.multiply(
            halo, Image.new("L", art.size, int(255 * GLOW_STRENGTH)))
    glow = Image.new("RGBA", art.size, GLOW_RGB + (0,))
    glow.putalpha(halo)
    # Stack the bloom so it still reads at 48 px on a dark dock; a single
    # pass washes out completely at that size.
    out = glow
    for _ in range(GLOW_PASSES - 1):
        out = Image.alpha_composite(out, glow)
    return Image.alpha_composite(out, art)


def emit(art: Image.Image, name: str) -> None:
    for size in SIZES:
        icon = art.resize((size, size), Image.LANCZOS)
        # Detail is lost below ~48px; a light sharpen keeps the silhouette
        # readable instead of a blurry smudge.
        if size <= 48:
            icon = icon.filter(ImageFilter.UnsharpMask(radius=1, percent=80, threshold=2))
        d = OUT / f"{size}x{size}" / "apps"
        d.mkdir(parents=True, exist_ok=True)
        icon.save(d / f"{name}.png", "PNG", optimize=True)
    print(f"   {name}: {len(SIZES)} sizes")


def main() -> None:
    if not SRC.exists():
        sys.exit(f"E: missing source logo {SRC}")
    art = build_rgba(SRC)
    print(f"I: source {SRC.name}, artwork cropped to {art.size[0]}x{art.size[1]} square")

    emit(art, NAME)
    emit(add_glow(art), LAUNCHER)

    native = max(art.size)
    if native < 512:
        print(f"W: artwork is only {native}px; 512px icon is an upscale")


if __name__ == "__main__":
    main()
