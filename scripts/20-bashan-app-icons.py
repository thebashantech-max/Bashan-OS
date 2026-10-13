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

from _palette import ROOT, VARIANTS, rgb_tuple

SRC = ROOT / "assets/branding/logo-source.jpg"
OUT = ROOT / "apps/rootfs/usr/share/icons/hicolor"
# The light launcher goes into its own tree, which 10-lb-config.sh lays over
# a copy of the icon theme to build "Bashan-Light". Same icon NAME, different
# artwork per theme - that is what lets plasma-changeicons swap the launcher
# glow without touching the dock's applet configuration.
OUT_LIGHT = ROOT / "theme/icons/_launcher-light"
NAME = "bashan-app"
LAUNCHER = "bashan-launcher"
SIZES = (16, 22, 24, 32, 48, 64, 128, 256, 512)
# Bloom behind the dock launcher button. Colour and strength come from the
# palette: on a dark pill a bright cyan halo reads, on a light pill the same
# halo is invisible, so the light variant uses a darker, weaker glow.
GLOW_PAD = 1.34
GLOW_RADIUS = 0.055
GLOW_PASSES = 2

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


def add_glow(art: Image.Image, v) -> Image.Image:
    """Bloom behind the mark, for the dock launcher button."""
    glow_rgb = rgb_tuple(v.pal["glow_rgb"])
    glow_strength = float(v.pal["glow_strength"])
    # Pad first: a halo blurred right up to the canvas edge gets clipped and
    # reads as a cyan square rather than a glow.
    side = int(art.size[0] * GLOW_PAD)
    padded = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    off = (side - art.size[0]) // 2
    padded.paste(art, (off, off))

    halo = padded.getchannel("A").filter(
        ImageFilter.GaussianBlur(max(1, int(side * GLOW_RADIUS))))
    halo = ImageChops.multiply(
        halo, Image.new("L", padded.size, int(255 * glow_strength)))
    glow = Image.new("RGBA", padded.size, glow_rgb + (0,))
    glow.putalpha(halo)
    # Two passes so it still reads at 48 px on a dark dock.
    out = glow
    for _ in range(GLOW_PASSES - 1):
        out = Image.alpha_composite(out, glow)
    return Image.alpha_composite(out, padded)


def emit(art: Image.Image, name: str, root: Path = None) -> None:
    root = OUT if root is None else root
    for size in SIZES:
        icon = art.resize((size, size), Image.LANCZOS)
        # Detail is lost below ~48px; a light sharpen keeps the silhouette
        # readable instead of a blurry smudge.
        if size <= 48:
            icon = icon.filter(ImageFilter.UnsharpMask(radius=1, percent=80, threshold=2))
        d = root / f"{size}x{size}" / "apps"
        d.mkdir(parents=True, exist_ok=True)
        icon.save(d / f"{name}.png", "PNG", optimize=True)
    print(f"   {name}: {len(SIZES)} sizes")


def main() -> None:
    if not SRC.exists():
        sys.exit(f"E: missing source logo {SRC}")
    art = build_rgba(SRC)
    print(f"I: source {SRC.name}, artwork cropped to {art.size[0]}x{art.size[1]} square")

    emit(art, NAME)
    emit(add_glow(art, VARIANTS["dark"]), LAUNCHER)
    # Same icon name, light-tuned artwork, in the overlay tree.
    emit(add_glow(art, VARIANTS["light"]), LAUNCHER, OUT_LIGHT)

    native = max(art.size)
    if native < 512:
        print(f"W: artwork is only {native}px; 512px icon is an upscale")


if __name__ == "__main__":
    main()
