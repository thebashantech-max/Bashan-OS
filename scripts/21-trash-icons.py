#!/usr/bin/env python3
"""Generate the Bashan trash icons from assets/reference/trash-icons.jpg.

The reference is a 1280x640 presentation sheet holding two rounded tiles:
the empty bin (left) and the full bin (right). Both are glass containers
shaped like the map of Syria. The full one has Arabic text etched into the
glass, so we emit two variants:

  A  faithful  - the text is kept exactly as drawn
  B  text-free - the text is inpainted away

The dark rounded tile behind each shape is a presentation device, not part of
the icon, so it is dropped: a desktop icon needs a transparent background.
Alpha is derived from brightness, which is what makes glass read as glass -
the dark interior stays see-through and only the rim, sheen and contents
remain solid.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from _palette import VARIANTS

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/reference/trash-icons.jpg"
OUT = ROOT / "theme/icons"
SIZES = (16, 22, 24, 32, 48, 64, 128, 256)
# Which full-bin artwork the light theme uses. Mirrors TRASH_VARIANT in
# config/build.conf; B is the text-free one.
TRASH_LIGHT_VARIANT = "B"

# Measured tile rectangles (x0, y0, x1, y1) - the full rounded square.
TILE_EMPTY = (64, 70, 588, 553)
TILE_FULL = (693, 70, 1217, 553)
# The tile has a bright rim and rounded corners that would otherwise show up
# as stray arcs in the icon. A uniform inset cannot remove them without also
# clipping the glass where it reaches toward an edge, so we mask the tile's
# actual rounded-rectangle shape instead.
TILE_RADIUS = 80
TILE_ERODE = 16
# Arabic text region, in full-image coordinates, plus the parameters that
# keep the glass rim out of the mask (measured from the reference).
TEXT_REGION = (862, 192, 1018, 318)
TEXT_LEVEL = 70
TEXT_DILATE = 7
DIFFUSE_ITERS = 400
# Brightness below this is tile background, not glass.
FLOOR = 30
GAIN = 2.2
MARGIN = 0.03


def _label(mask: np.ndarray) -> tuple:
    """Flood-fill connected-component labelling (8-connected).

    scipy is not a build dependency and the region is ~150x130 px, so a plain
    stack-based fill is cheaper than adding one.
    """
    h, w = mask.shape
    lab = np.zeros((h, w), dtype=np.int32)
    n = 0
    for sy in range(h):
        for sx in range(w):
            if mask[sy, sx] and lab[sy, sx] == 0:
                n += 1
                stack = [(sy, sx)]
                lab[sy, sx] = n
                while stack:
                    y, x = stack.pop()
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = y + dy, x + dx
                            if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] \
                                    and lab[ny, nx] == 0:
                                lab[ny, nx] = n
                                stack.append((ny, nx))
    return lab, n


def inpaint_text(img: np.ndarray) -> np.ndarray:
    """Erase the etched Arabic text without damaging the glass.

    The glass's wavy top rim runs straight through the text's bounding box,
    so neither a rectangular patch nor a per-column rim estimate works: both
    eat part of the rim. Instead every bright shape in the region is labelled,
    and only shapes that touch no edge of the region are removed. The rim and
    the contents run out of the region on at least one side, so they survive;
    the glyphs float free, so they go. The holes are then filled by diffusion,
    which reproduces the smooth dark gradient behind the text.
    """
    x0, y0, x1, y1 = TEXT_REGION
    lum = img.max(axis=2)
    region = lum[y0:y1, x0:x1]

    lab, n = _label(region > TEXT_LEVEL)
    h, w = region.shape
    edge = set(lab[0, :]) | set(lab[h - 1, :]) | set(lab[:, 0]) | set(lab[:, w - 1])
    floating = [i for i in range(1, n + 1) if i not in edge]
    if not floating:
        return img.copy()
    mask = np.isin(lab, floating)

    # Grow it so each stroke's soft embossed edge goes too.
    mask = np.asarray(Image.fromarray((mask * 255).astype(np.uint8))
                      .filter(ImageFilter.MaxFilter(TEXT_DILATE))) > 127

    out = img.copy()
    sub = out[y0:y1, x0:x1].astype(np.float32).copy()
    sub[mask] = np.nan
    for _ in range(DIFFUSE_ITERS):
        filled = np.nan_to_num(sub)
        weight = (~np.isnan(sub)).astype(np.float32)
        acc = np.zeros_like(filled)
        wacc = np.zeros_like(weight)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            acc += np.roll(filled, (dy, dx), axis=(0, 1))
            wacc += np.roll(weight, (dy, dx), axis=(0, 1))
        sub = np.where(np.isnan(sub) & (wacc > 0),
                       np.divide(acc, np.maximum(wacc, 1e-6)), sub)
    out[y0:y1, x0:x1] = np.nan_to_num(sub)
    print(f"I: text removal - {n} bright shapes in region, "
          f"{len(floating)} floating (erased), {len(edge & set(range(1, n + 1)))} kept")
    return out


def tile_mask(w: int, h: int) -> np.ndarray:
    """Soft mask of the tile interior, excluding its bright rim and corners."""
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [TILE_ERODE, TILE_ERODE, w - 1 - TILE_ERODE, h - 1 - TILE_ERODE],
        radius=TILE_RADIUS - TILE_ERODE, fill=255)
    m = m.filter(ImageFilter.GaussianBlur(4))
    return np.asarray(m).astype(np.float32) / 255.0


def to_icon(img: np.ndarray, box: tuple) -> Image.Image:
    x0, y0, x1, y1 = box
    region = img[y0:y1, x0:x1]
    keep = tile_mask(region.shape[1], region.shape[0])
    lum = region.max(axis=2) * keep

    ys, xs = np.nonzero(lum > FLOOR + 10)
    if len(xs) == 0:
        sys.exit("E: no glass found in tile")
    a0, a1, b0, b1 = xs.min(), xs.max(), ys.min(), ys.max()
    pad = int(round(max(a1 - a0, b1 - b0) * MARGIN))
    a0, b0 = max(0, a0 - pad), max(0, b0 - pad)
    a1 = min(region.shape[1] - 1, a1 + pad)
    b1 = min(region.shape[0] - 1, b1 + pad)

    rgb = region[b0:b1 + 1, a0:a1 + 1]
    lum = lum[b0:b1 + 1, a0:a1 + 1]
    alpha = np.clip((lum - FLOOR) * GAIN, 0, 255) * keep[b0:b1 + 1, a0:a1 + 1]

    art = Image.fromarray(
        np.dstack([np.clip(rgb, 0, 255), alpha]).astype(np.uint8), "RGBA")
    side = max(art.size)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(art, ((side - art.width) // 2, (side - art.height) // 2))
    return canvas


def for_light(art: Image.Image) -> Image.Image:
    """The same glass, given an edge so it reads on a light background.

    The artwork is unchanged - this is a re-cut, not a redesign, and the
    dark-mode icons it came from are not touched. The problem on light is
    only contrast: alpha is derived from brightness, so the parts that
    survive are the bright rim and sheen, and bright-on-light disappears.

    A soft dark halo is laid UNDER the glass, taken from the shape's own
    alpha. That gives the silhouette a definite edge without drawing a
    stroke over the artwork or altering a single pixel of the glass itself.
    """
    pal = VARIANTS["light"].pal
    h = pal["text"].lstrip("#")
    shadow_rgb = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

    a = art.getchannel("A")
    # A TIGHT blur, not a soft one. A wide halo reads as a smudge behind the
    # icon; a narrow one reads as the edge of the glass, which is what is
    # missing on a pale background.
    halo = a.filter(ImageFilter.GaussianBlur(max(1, art.size[0] // 260)))
    halo = halo.point(lambda v: min(255, int(v * 2.4)))
    shadow = Image.new("RGBA", art.size, shadow_rgb + (0,))
    shadow.putalpha(halo.point(lambda v: int(v * 0.62)))

    out = Image.alpha_composite(shadow, art)

    # The glass body is lit for a dark scene, so on white it is nearly the
    # same value as the page. Deepening it a little gives it substance
    # without touching its shape or its transparency.
    rgb = out.convert("RGB").point(lambda v: int(((v / 255) ** 1.22) * 255))
    rgb.putalpha(out.getchannel("A"))
    return rgb


def emit(art: Image.Image, variant: str, name: str, root: Path = None) -> None:
    for size in SIZES:
        icon = art.resize((size, size), Image.LANCZOS)
        if size <= 48:
            icon = icon.filter(ImageFilter.UnsharpMask(radius=1, percent=70, threshold=2))
        base = OUT / f"Bashan-{variant}" if root is None else root
        d = base / f"{size}x{size}" / "places"
        d.mkdir(parents=True, exist_ok=True)
        icon.save(d / f"{name}.png", "PNG", optimize=True)


def main() -> None:
    if not SRC.exists():
        sys.exit(f"E: missing {SRC}")
    img = np.asarray(Image.open(SRC).convert("RGB")).astype(np.float32)

    empty = to_icon(img, TILE_EMPTY)
    full_a = to_icon(img, TILE_FULL)
    full_b = to_icon(inpaint_text(img), TILE_FULL)
    print(f"I: empty {empty.size[0]}px square, full {full_a.size[0]}px square")

    for variant, full in (("A", full_a), ("B", full_b)):
        emit(empty, variant, "user-trash")
        emit(full, variant, "user-trash-full")
        print(f"   variant {variant}: {len(SIZES)} sizes x 2 states -> "
              f"{(OUT / f'Bashan-{variant}').relative_to(ROOT)}")

    # Light-mode re-cut. Goes into the Bashan-Light icon theme overlay, so
    # the dark icons above keep exactly the artwork from the reference and
    # the light theme gets its own copies under the same names.
    light_root = OUT / "_light"
    chosen_full = full_b if TRASH_LIGHT_VARIANT == "B" else full_a
    emit(for_light(empty), "", "user-trash", light_root)
    emit(for_light(chosen_full), "", "user-trash-full", light_root)
    print(f"   light re-cut: {len(SIZES)} sizes x 2 states -> "
          f"{light_root.relative_to(ROOT)}")

    # Large masters for the previews and for any later retouching.
    d = OUT / "_masters"
    d.mkdir(parents=True, exist_ok=True)
    empty.save(d / "trash-empty.png")
    full_a.save(d / "trash-full-A.png")
    full_b.save(d / "trash-full-B.png")


if __name__ == "__main__":
    main()
