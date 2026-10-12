#!/usr/bin/env python3
"""Generate the Bashan layered mountain-ridge wallpapers.

Fully procedural: no source image, no Inkscape, nothing to re-license. The
scene is a vertical sky gradient, a soft cyan horizon glow, then a stack of
ridge silhouettes built from 1-D fractal noise, each hazier and lighter the
further back it sits.

Deterministic: SEED fixes the ridge shapes, so a rebuild produces identical
files. Change SEED to get a different mountain range.

Outputs 4K, 1080p and a login variant (darker, stronger vignette, so the SDDM
password field stays readable over it).
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PAL = json.loads((ROOT / "theme/palette.json").read_text())
OUT = ROOT / "theme/wallpapers"
SEED = 20261012

# (baseline height, amplitude, roughness, colour token, haze, ridgedness)
# Perspective: a distant range packs many small peaks into the same screen
# width, a near one shows few large ones. So roughness falls and amplitude
# rises as the ranges come forward - the reverse looks like waves, not rock.
LAYERS = [
    (0.57, 0.042, 5.5, "ridge_far",  0.60, 0.88),
    (0.63, 0.058, 4.2, "ridge_far",  0.46, 0.88),
    (0.70, 0.082, 3.1, "ridge_mid",  0.32, 0.90),
    (0.79, 0.112, 2.2, "ridge_mid",  0.19, 0.92),
    (0.89, 0.150, 1.6, "ridge_near", 0.08, 0.93),
    (1.03, 0.195, 1.1, "ridge_near", 0.00, 0.95),
]


def hexrgb(h: str) -> np.ndarray:
    h = h.lstrip("#")[:6]
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def fbm(width: int, octaves: int, rough: float, rng, ridged: float = 0.0) -> np.ndarray:
    """1-D fractal noise in [0,1].

    `ridged` folds each octave around its midpoint, which turns smooth rolling
    curves into sharp crests - the difference between hills and mountains.
    0 is plain noise, 1 is fully ridged.
    """
    x = np.linspace(0.0, 1.0, width, dtype=np.float32)
    total = np.zeros(width, dtype=np.float32)
    amp, freq, norm = 1.0, 2.0 * rough, 0.0
    for _ in range(octaves):
        n = max(3, int(freq) + 1)
        pts = rng.random(n + 1).astype(np.float32)
        pts[-1] = pts[0]                      # wrap, so no seam at the edges
        pos = x * n
        i = np.floor(pos).astype(int)
        f = pos - i
        f = f * f * (3.0 - 2.0 * f)           # smoothstep
        oct_ = pts[i] * (1 - f) + pts[np.minimum(i + 1, n)] * f
        if ridged:
            sharp = 1.0 - np.abs(2.0 * oct_ - 1.0)
            oct_ = oct_ * (1.0 - ridged) + (sharp * sharp) * ridged
        total += amp * oct_
        norm += amp
        amp *= 0.5
        freq *= 2.0
    return total / norm


def render(w: int, h: int, login: bool) -> Image.Image:
    rng = np.random.default_rng(SEED)
    yy = np.arange(h, dtype=np.float32)[:, None]

    # Sky: vertical gradient from near-black to a faint navy at the horizon.
    t = (np.arange(h, dtype=np.float32) / (h - 1))[:, None, None]
    img = hexrgb(PAL["sky_top"]) * (1 - t) + hexrgb(PAL["sky_horizon"]) * t
    img = np.repeat(img, w, axis=1)

    # A soft cyan bloom sitting on the horizon, the one spot of colour.
    gx = np.linspace(-1, 1, w, dtype=np.float32)[None, :]
    gy = (np.arange(h, dtype=np.float32)[:, None] / h - 0.62) * 3.4
    glow = np.exp(-(gx * gx) * 1.6) * np.exp(-(gy * gy) * 2.2)
    img += hexrgb(PAL["accent_deep"])[None, None, :] * glow[:, :, None] * (0.16 if login else 0.30)

    # Ridges, far to near. Each is a filled silhouette with a 1 px soft edge
    # and a touch of haze so distance reads.
    for base, ampl, rough, tok, haze, ridged in LAYERS:
        ridge = fbm(w, 7, rough, rng, ridged)
        line = (base - ampl * (ridge - 0.5) * 2.0) * h
        cov = np.clip(yy - line[None, :] + 0.5, 0.0, 1.0)[:, :, None]
        colour = hexrgb(PAL[tok]) * (1.0 - haze) + hexrgb(PAL["sky_horizon"]) * haze
        img = img * (1.0 - cov) + colour[None, None, :] * cov

        # Faint cyan rim light along the crest of the distant ridges only.
        if haze > 0.25:
            rim = np.clip(1.0 - np.abs(yy - line[None, :]) / 2.5, 0.0, 1.0)[:, :, None]
            img += hexrgb(PAL["accent"])[None, None, :] * rim * 0.05

    # Vignette: stronger on the login wallpaper so the form stays legible.
    vx = np.linspace(-1, 1, w, dtype=np.float32)[None, :]
    vy = np.linspace(-1, 1, h, dtype=np.float32)[:, None]
    vig = 1.0 - (vx * vx + vy * vy) * (0.34 if login else 0.18)
    img *= np.clip(vig, 0.0, 1.0)[:, :, None]

    if login:
        img *= 0.72

    # Dither before the 8-bit quantise. Without this, a dark smooth gradient
    # bands into visible stripes on exactly the kind of panel this ships on.
    img += rng.normal(0.0, 0.7, img.shape).astype(np.float32)
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    jobs = [("bashan-ridge-3840x2160.png", 3840, 2160, False),
            ("bashan-ridge-1920x1080.png", 1920, 1080, False),
            ("bashan-ridge-login-1920x1080.png", 1920, 1080, True)]
    for name, w, h, login in jobs:
        render(w, h, login).save(OUT / name, "PNG", optimize=True)
        mb = (OUT / name).stat().st_size / 1e6
        print(f"   {name:<36} {w}x{h}  {mb:.1f} MB")


if __name__ == "__main__":
    main()
