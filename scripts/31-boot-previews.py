#!/usr/bin/env python3
"""Mockups of the boot chain for owner approval.

Drawn from the real generated assets. Not screenshots: nothing has booted.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
PAL = json.loads((ROOT / "theme/palette.json").read_text())
OUT = ROOT / "build/previews"
PL = ROOT / "branding/plymouth/bashan"
GR = ROOT / "branding/grub/bashan"
SD = ROOT / "branding/sddm/bashan"
LOGO_SIZES = (256, 384, 512, 640, 815)
NATIVE_CAP = 815
IMAGE_FRACTION = 0.40


def c(tok, a=255):
    h = PAL[tok].lstrip("#")[:6]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


def pick(target):
    return min((s for s in LOGO_SIZES if s >= target), default=LOGO_SIZES[-1])


def plymouth_panel(w, h, label):
    """One splash at a given panel size, rendered at true proportions."""
    im = Image.new("RGBA", (w, h), c("sky_top"))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / max(h - 1, 1)
        d.line([(0, y), (w, y)],
               fill=tuple(int(c("sky_top")[i] * (1 - t) + c("bg_void")[i] * t)
                          for i in range(3)))
    target = min(h * IMAGE_FRACTION, NATIVE_CAP)
    src = Image.open(PL / f"logo-{pick(target)}.png")
    s = int(round(target))
    im.alpha_composite(src.resize((s, s), Image.LANCZOS),
                       ((w - s) // 2, (h - s) // 2))
    d.text((14, h - 28), label, fill=c("text_faint"))
    return im


def plymouth_preview():
    """1080p vs 4K, shown at the same display width so the logo's relative
    size is directly comparable."""
    W = 980
    a = plymouth_panel(1920, 1080, "1920x1080   artwork 304px = 28.2% of height   (downscaled from the 512px asset)")
    b = plymouth_panel(3840, 2160, "3840x2160   artwork 574px = 26.6% of height   (native size, no scaling at all)")
    a = a.resize((W, int(W * 1080 / 1920)), Image.LANCZOS)
    b = b.resize((W, int(W * 2160 / 3840)), Image.LANCZOS)
    H = a.height + b.height + 96
    out = Image.new("RGBA", (W + 40, H), c("bg_void"))
    d = ImageDraw.Draw(out)
    d.text((20, 16), "PLYMOUTH BOOT SPLASH - same screen width, so the logo's",
           fill=c("text"))
    d.text((20, 34), "relative size is directly comparable", fill=c("text"))
    out.alpha_composite(a, (20, 60))
    out.alpha_composite(b, (20, 60 + a.height + 20))
    out.convert("RGB").save(OUT / "05-plymouth.png")


def grub_preview():
    bg = Image.open(GR / "background.png").convert("RGBA")
    W, H = bg.size
    d = ImageDraw.Draw(bg)
    logo = Image.open(GR / "logo.png")
    bg.alpha_composite(logo, (W // 2 - 90, int(H * 0.12)))
    d.text((W // 2 - 48, int(H * 0.12) + 200), "Bashan OS", fill=c("text"))
    entries = ["Bashan OS", "Advanced options for Bashan OS",
               "Windows Boot Manager (on /dev/nvme0n1p1)",
               "UEFI Firmware Settings"]
    top = int(H * 0.42)
    for i, e in enumerate(entries):
        y = top + i * 44
        if i == 0:
            d.rounded_rectangle([int(W * 0.25), y - 6, int(W * 0.75), y + 30],
                                radius=8, fill=c("accent_deep", 90),
                                outline=c("accent", 200), width=1)
        d.text((int(W * 0.27), y), e,
               fill=c("accent") if i == 0 else c("text_dim"))
    d.text((W // 2 - 150, int(H * 0.88)),
           "Use the arrow keys to choose, then press Enter", fill=c("text_faint"))
    d.text((W // 2 - 48, int(H * 0.94)), "Bashan Tech LLC", fill=c("text_faint"))
    d.text((20, H - 28), "MOCKUP of the GRUB menu. The Windows entry shows what "
                         "dual boot looks like once os-prober finds it.",
           fill=c("text_faint"))
    bg.convert("RGB").save(OUT / "06-grub.png")


def sddm_preview():
    bg = Image.open(SD / "background.png").convert("RGBA")
    W, H = bg.size
    d = ImageDraw.Draw(bg)
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for y in range(H):
        sd.line([(0, y), (W, y)], fill=(0, 0, 0, int(150 * (y / H) ** 2)))
    bg.alpha_composite(shade)

    logo = Image.open(SD / "logo.png").resize((150, 150), Image.LANCZOS)
    cx, cy = W // 2, H // 2
    bg.alpha_composite(logo, (cx - 75, cy - 280))
    d.text((cx - 44, cy - 115), "Bashan OS", fill=c("text"))

    card = Image.new("RGBA", (420, 196), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle([0, 0, 419, 195], radius=18, fill=c("bg_raised", 235),
                         outline=c("border_light"), width=1)
    cd.rounded_rectangle([22, 22, 397, 62], radius=10, fill=c("bg_base"),
                         outline=c("border"), width=1)
    cd.text((36, 34), "simple", fill=c("text"))
    cd.polygon([(370, 38), (382, 38), (376, 46)], fill=c("text_dim"))
    cd.rounded_rectangle([22, 74, 397, 114], radius=10, fill=c("bg_deep"),
                         outline=c("accent"), width=1)
    cd.text((36, 86), "Password", fill=c("text_faint"))
    cd.rounded_rectangle([22, 128, 397, 172], radius=10, fill=c("accent_deep"))
    cd.text((180, 143), "Log in", fill=c("text"))
    bg.alpha_composite(card, (cx - 210, cy - 80))

    d.text((30, H - 60), "Session", fill=c("text_dim"))
    d.rounded_rectangle([96, H - 66, 326, H - 32], radius=8,
                        fill=c("bg_raised", 200), outline=c("border"), width=1)
    d.text((110, H - 58), "Plasma (Wayland)", fill=c("text"))
    d.text((W - 260, H - 58), "Restart", fill=c("text_dim"))
    d.text((W - 150, H - 58), "Shut down", fill=c("text_dim"))
    d.text((20, H - 26), "MOCKUP of the SDDM login theme.", fill=c("text_faint"))
    bg.convert("RGB").save(OUT / "07-sddm.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    plymouth_preview(); print("   build/previews/05-plymouth.png")
    grub_preview();     print("   build/previews/06-grub.png")
    sddm_preview();     print("   build/previews/07-sddm.png")


if __name__ == "__main__":
    main()
