#!/usr/bin/env python3
"""Render design previews for owner approval.

These are MOCKUPS drawn from the real palette, the real wallpaper and the
real generated icons. They are not screenshots: nothing has run Plasma yet.
Stock app icons (Brave, Dolphin, Konsole, camera) are stand-in tiles, since
the Breeze icon set is not needed on the build host just to draw a preview.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from _palette import ROOT, VARIANTS

OUT = ROOT / "build/previews"
WALL = ROOT / "theme/wallpapers"
ICON = ROOT / "apps/rootfs/usr/share/icons/hicolor"
ICON_LIGHT = ROOT / "theme/icons/_launcher-light"

# Which variant is being drawn. main() swaps this and redraws everything,
# which is cheaper than threading a palette through every drawing helper.
CUR = VARIANTS["dark"]
PAL = CUR.pal


def c(tok, alpha=255):
    h = str(PAL[tok]).lstrip("#")
    v = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    return v + (int(h[6:8], 16) if len(h) == 8 else alpha,)


def icon(name, size):
    # The launcher has light-tuned artwork under the same name.
    if CUR.is_light and name == "bashan-launcher":
        return Image.open(ICON_LIGHT / f"{size}x{size}" / "apps" / f"{name}.png")
    return Image.open(ICON / f"{size}x{size}" / "apps" / f"{name}.png")


def stand_in(letter, size, tint):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([2, 2, size - 3, size - 3], radius=size // 4,
                        fill=tint, outline=c("border_light"), width=1)
    d.text((size / 2 - 4, size / 2 - 7), letter, fill=c("text"))
    return im


def glass_card(w, h, title, lines):
    card = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(card)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=16,
                        fill=c("bg_raised", 150), outline=c("border"), width=1)
    d.text((16, 12), title, fill=c("accent"))
    for i, ln in enumerate(lines):
        d.text((16, 38 + i * 18), ln, fill=c("text_dim"))
    return card


def desktop_mockup():
    bg = Image.open(WALL / f"bashan-ridge{CUR.suffix}-1920x1080.png").convert("RGBA")
    W, H = bg.size
    d = ImageDraw.Draw(bg)

    # --- desktop widgets -------------------------------------------------
    bg.alpha_composite(glass_card(300, 150, "System Monitor",
                                  ["CPU    12%", "Memory  1.4 GB", "Disk   28%"]), (56, 56))
    bg.alpha_composite(glass_card(300, 120, "Weather",
                                  ["Partly cloudy", "18 degrees"]), (56, 232))
    bg.alpha_composite(glass_card(300, 170, "Notes",
                                  ["shopping", "call Dad", "renew passport"]), (56, 378))

    # --- desktop trash icon, bottom-right (LTR locales) ------------------
    tr = Image.open(ROOT / "theme/icons/Bashan-B/64x64/places/user-trash-full.png")
    bg.alpha_composite(tr, (W - 130, H - 230))
    d.text((W - 142, H - 158), "Trash", fill=c("text"))

    # --- the dock --------------------------------------------------------
    S, GAP, PAD = 48, 16, 14
    apps = [("launcher", None), ("B", c("bg_surface")), ("C", c("bg_surface")),
            ("D", c("bg_surface")), ("bashan", None), ("K", c("bg_surface")),
            ("P", c("bg_surface"))]
    inner = len(apps) * S + (len(apps) - 1) * GAP
    tray_w = 150
    dw = inner + tray_w + PAD * 2 + 30
    dh = S + PAD * 2
    dx, dy = (W - dw) // 2, H - dh - 18        # small gap to the screen edge

    # blur what is behind the pill, then draw the pill over it
    region = bg.crop((dx, dy, dx + dw, dy + dh)).filter(ImageFilter.GaussianBlur(14))
    mask = Image.new("L", (dw, dh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, dw - 1, dh - 1], radius=dh // 2, fill=255)
    bg.paste(region, (dx, dy), mask)
    pill = Image.new("RGBA", (dw, dh), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pill)
    pd.rounded_rectangle([0, 0, dw - 1, dh - 1], radius=dh // 2,
                         fill=c("bg_base", 120), outline=c("border_light"), width=1)
    bg.alpha_composite(pill, (dx, dy))

    x = dx + PAD
    for i, (kind, tint) in enumerate(apps):
        if kind == "launcher":
            bg.alpha_composite(icon("bashan-launcher", S), (x, dy + PAD))
        elif kind == "bashan":
            bg.alpha_composite(icon("bashan-app", S), (x, dy + PAD))
        else:
            bg.alpha_composite(stand_in(kind, S, tint), (x, dy + PAD))
        # glowing mint active indicator under the running app
        if i == 4:
            glow = Image.new("RGBA", (S, 14), (0, 0, 0, 0))
            ImageDraw.Draw(glow).ellipse([S // 2 - 11, 4, S // 2 + 11, 9], fill=c("mint"))
            glow = glow.filter(ImageFilter.GaussianBlur(3))
            bg.alpha_composite(glow, (x, dy + dh - 14))
        x += S + GAP

    d.line([(x - GAP // 2, dy + 14), (x - GAP // 2, dy + dh - 14)], fill=c("border"), width=1)
    d.text((x + 6, dy + 20), "wifi  vol  batt", fill=c("text_dim"))
    d.text((x + 104, dy + 18), "21:40", fill=c("text"))

    d.text((40, H - 36), "MOCKUP - drawn from the real palette, wallpaper and generated "
                         "icons. Lettered tiles stand in for Brave / Chrome / Dolphin / "
                         "Konsole / camera.", fill=c("text_faint"))
    bg.convert("RGB").save(OUT / f"02-desktop-mockup{CUR.suffix}.png")


def palette_sheet():
    groups = [("Backgrounds", ["bg_void", "bg_deep", "bg_base", "bg_raised", "bg_surface"]),
              ("Borders", ["border_soft", "border", "border_light"]),
              ("Text", ["text", "text_dim", "text_faint"]),
              ("Accent", ["accent", "accent_dim", "accent_deep", "mint"]),
              ("Status", ["ok", "warn", "error"]),
              ("Scene", ["sky_top", "sky_horizon", "ridge_far", "ridge_mid", "ridge_near"])]
    W, H = 980, 120 + len(groups) * 108
    im = Image.new("RGB", (W, H), c("bg_void")[:3])
    d = ImageDraw.Draw(im)
    d.text((36, 30), "BASHAN OS - COLOUR PALETTE", fill=c("text"))
    d.text((36, 52), "accent hue sampled from the cyan glow in your logo, not invented",
           fill=c("text_faint"))
    y = 100
    for name, toks in groups:
        d.text((36, y), name, fill=c("text_dim"))
        x = 180
        for t in toks:
            d.rounded_rectangle([x, y - 14, x + 140, y + 54], radius=10,
                                fill=c(t), outline=c("border"), width=1)
            d.text((x + 10, y + 62), t, fill=c("text_faint"))
            d.text((x + 10, y + 78), PAL[t], fill=c("text_faint"))
            x += 156
        y += 108
    im.save(OUT / f"03-palette{CUR.suffix}.png")


def login_mockup():
    bg = Image.open(WALL / f"bashan-ridge{CUR.suffix}-login-1920x1080.png").convert("RGBA")
    W, H = bg.size
    d = ImageDraw.Draw(bg)
    bg.alpha_composite(icon("bashan-launcher", 128), (W // 2 - 64, H // 2 - 230))
    card = Image.new("RGBA", (420, 180), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle([0, 0, 419, 179], radius=20, fill=c("bg_raised", 170),
                         outline=c("border_light"), width=1)
    cd.text((150, 24), "Bashan OS", fill=c("text"))
    cd.rounded_rectangle([40, 70, 379, 112], radius=10, fill=c("bg_deep", 200),
                         outline=c("accent"), width=1)
    cd.text((56, 85), "Password", fill=c("text_faint"))
    cd.rounded_rectangle([150, 128, 269, 160], radius=16, fill=c("accent_deep"))
    cd.text((194, 138), "Log in", fill=c("text"))
    bg.alpha_composite(card, (W // 2 - 210, H // 2 - 60))
    d.text((40, H - 36), "MOCKUP of the login screen wallpaper. The SDDM theme itself "
                         "is built in Stage 7.", fill=c("text_faint"))
    bg.convert("RGB").save(OUT / f"04-login-mockup{CUR.suffix}.png")


def main():
    global CUR, PAL
    OUT.mkdir(parents=True, exist_ok=True)
    for v in VARIANTS.values():
        CUR, PAL = v, v.pal
        desktop_mockup(); print(f"   build/previews/02-desktop-mockup{v.suffix}.png")
        palette_sheet();  print(f"   build/previews/03-palette{v.suffix}.png")
        login_mockup();   print(f"   build/previews/04-login-mockup{v.suffix}.png")


if __name__ == "__main__":
    main()
