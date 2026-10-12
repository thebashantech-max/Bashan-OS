#!/usr/bin/env python3
"""Mockups of every Calamares screen, for owner approval.

Drawn from the real branding assets and the real module configuration, so
what is shown matches what the configs say will happen. Not screenshots:
Calamares has not been run.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
PAL = json.loads((ROOT / "theme/palette.json").read_text())
OUT = ROOT / "build/previews"
BR = ROOT / "installer/branding/bashan"
W, H = 920, 620
SIDEBAR = 210
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONTB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
ARABIC = "/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf"

STEPS = ["Welcome", "Location", "Keyboard", "Disk setup",
         "Your account", "Summary", "Install", "Finish"]


def f(size, bold=False):
    return ImageFont.truetype(FONTB if bold else FONT, size)


def c(tok, a=255):
    h = PAL[tok].lstrip("#")[:6]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


def chrome(active):
    """The installer window: sidebar with steps, content area, buttons."""
    im = Image.new("RGBA", (W, H), c("bg_base"))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, SIDEBAR, H], fill=c("bg_deep"))

    logo = Image.open(BR / "logo.png").resize((64, 64), Image.LANCZOS)
    im.alpha_composite(logo, (22, 20))
    d.text((96, 36), "Bashan OS", font=f(15, True), fill=c("text"))
    d.text((96, 56), "1.0", font=f(11), fill=c("text_faint"))

    y = 118
    for i, s in enumerate(STEPS):
        if i == active:
            d.rounded_rectangle([10, y - 7, SIDEBAR - 12, y + 23], radius=8,
                                fill=c("accent_deep"))
        dot = c("accent") if i <= active else c("border")
        d.ellipse([24, y + 3, 34, y + 13], fill=dot)
        d.text((48, y), s, font=f(12, i == active),
               fill=c("text") if i == active else c("text_dim"))
        y += 42

    d.text((22, H - 36), "Bashan Tech LLC", font=f(9), fill=c("text_faint"))
    d.line([(SIDEBAR, 0), (SIDEBAR, H)], fill=c("border_soft"))
    d.line([(SIDEBAR, H - 66), (W, H - 66)], fill=c("border_soft"))
    return im, d


def button(d, x, y, label, kind="normal", w=110):
    fill = {"normal": c("bg_surface"), "primary": c("accent_deep"),
            "danger": ("#7f1d1d"), "ghost": c("bg_base")}[kind]
    d.rounded_rectangle([x, y, x + w, y + 38], radius=8, fill=fill,
                        outline=c("accent") if kind == "primary" else c("border"),
                        width=1)
    tw = d.textlength(label, font=f(12))
    d.text((x + (w - tw) / 2, y + 11), label, font=f(12),
           fill=c("text") if kind != "ghost" else c("text_dim"))


def footer(d, back=True, nxt="Next", kind="primary"):
    if back:
        button(d, SIDEBAR + 24, H - 54, "Back", "ghost", 90)
    button(d, W - 250, H - 54, "Cancel", "ghost", 90)
    button(d, W - 146, H - 54, nxt, kind, 122)


def heading(d, title, sub=None, y=40):
    d.text((SIDEBAR + 34, y), title, font=f(21, True), fill=c("text"))
    if sub:
        d.text((SIDEBAR + 34, y + 34), sub, font=f(12), fill=c("text_dim"))


def wrap(d, text, x, y, width, font, fill, lh=19):
    words, line = text.split(), ""
    for wd in words:
        t = (line + " " + wd).strip()
        if d.textlength(t, font=font) > width:
            d.text((x, y), line, font=font, fill=fill); y += lh; line = wd
        else:
            line = t
    if line:
        d.text((x, y), line, font=font, fill=fill); y += lh
    return y


# --------------------------------------------------------------------------
def s_welcome():
    im, d = chrome(0)
    heading(d, "Welcome", "Choose your language to begin")
    x = SIDEBAR + 34
    langs = [("English", "English", None), ("العربية", "Arabic", ARABIC),
             ("Deutsch", "German", None), ("Español", "Spanish", None)]
    d.rounded_rectangle([x, 118, W - 40, 350], radius=10, fill=c("bg_deep"),
                        outline=c("border"), width=1)
    y = 130
    for i, (native, eng, fp) in enumerate(langs):
        if i == 0:
            d.rounded_rectangle([x + 6, y - 2, W - 46, y + 48], radius=8,
                                fill=c("accent_deep"))
        fnt = ImageFont.truetype(fp, 20) if fp else f(20)
        d.text((x + 22, y + 6), native, font=fnt, fill=c("text"))
        d.text((x + 230, y + 12), eng, font=f(13), fill=c("text_dim"))
        y += 54
    d.text((x, 362), "9 more languages below", font=f(11), fill=c("text_faint"))
    wrap(d, "Bashan OS will be installed on this computer. Nothing is changed "
            "until you have seen exactly what will happen and agreed to it.",
         x, 400, W - x - 40, f(12), c("text_dim"))
    d.ellipse([x, 452, x + 16, 468], outline=c("ok"), width=2)
    d.text((x + 26, 450), "This computer meets the requirements",
           font=f(12), fill=c("ok"))
    footer(d, back=False)
    return im


def s_location():
    im, d = chrome(1)
    heading(d, "Location", "So the clock and date formats are right")
    x = SIDEBAR + 34
    d.rounded_rectangle([x, 118, W - 40, 330], radius=10, fill=c("bg_deep"),
                        outline=c("border"), width=1)
    d.text((x + 24, 150), "Region", font=f(12), fill=c("text_dim"))
    d.rounded_rectangle([x + 24, 172, x + 300, 212], radius=8,
                        fill=c("bg_raised"), outline=c("border"), width=1)
    d.text((x + 38, 183), "Europe", font=f(13), fill=c("text"))
    d.text((x + 24, 230), "Zone", font=f(12), fill=c("text_dim"))
    d.rounded_rectangle([x + 24, 252, x + 300, 292], radius=8,
                        fill=c("bg_raised"), outline=c("border"), width=1)
    d.text((x + 38, 263), "Berlin", font=f(13), fill=c("text"))
    wrap(d, "Guessed from your internet connection. Change it if it is wrong.",
         x, 348, W - x - 40, f(12), c("text_faint"))
    footer(d)
    return im


def s_keyboard():
    im, d = chrome(2)
    heading(d, "Keyboard", "Type in the box to check it works")
    x = SIDEBAR + 34
    d.rounded_rectangle([x, 118, W - 40, 300], radius=10, fill=c("bg_deep"),
                        outline=c("border"), width=1)
    for i, (k, v) in enumerate([("Layout", "Arabic (Syria)"),
                                ("Second layout", "English (US)")]):
        d.text((x + 24, 146 + i * 64), k, font=f(12), fill=c("text_dim"))
        d.rounded_rectangle([x + 170, 138 + i * 64, x + 450, 176 + i * 64],
                            radius=8, fill=c("bg_raised"),
                            outline=c("border"), width=1)
        d.text((x + 184, 148 + i * 64), v, font=f(13), fill=c("text"))
    d.rounded_rectangle([x + 24, 240, W - 64, 280], radius=8, fill=c("bg_void"),
                        outline=c("accent"), width=1)
    d.text((x + 38, 252), "Type here to test", font=f(12), fill=c("text_faint"))
    wrap(d, "Both layouts are installed. Press both Alt keys together to switch "
            "between them at any time.", x, 318, W - x - 40, f(12), c("text_faint"))
    footer(d)
    return im


def s_disk():
    im, d = chrome(3)
    heading(d, "Disk setup", "Nothing is selected. You must choose.")
    x = SIDEBAR + 34
    d.rounded_rectangle([x, 112, W - 40, 150], radius=8, fill=c("bg_raised"),
                        outline=c("border"), width=1)
    d.text((x + 16, 123), "Disk:  Samsung SSD 860 EVO  500 GB  (/dev/sda)",
           font=f(12), fill=c("text"))

    opts = [("Install alongside Windows 11",
             "Keeps Windows and your files. You pick which one to start each time.", "safe"),
            ("Replace a partition",
             "Replaces one partition only. Everything else on the disk is kept.", "warn"),
            ("Erase the whole disk",
             "Deletes Windows 11 and every file on this disk. This cannot be undone.", "danger"),
            ("Manual partitioning",
             "For people who want to set the partitions up themselves.", "safe")]
    y = 168
    for label, desc, kind in opts:
        col = {"safe": c("border"), "warn": c("warn"), "danger": c("error")}[kind]
        d.ellipse([x + 8, y + 8, x + 26, y + 26], outline=col, width=2)
        d.text((x + 40, y + 6), label, font=f(14, kind == "danger"),
               fill=c("error") if kind == "danger" else c("text"))
        wrap(d, desc, x + 40, y + 28, W - x - 90, f(11),
             c("error") if kind == "danger" else c("text_dim"), 15)
        y += 74

    d.rounded_rectangle([x, y + 4, W - 40, y + 44], radius=8,
                        fill=(127, 29, 29, 70), outline=c("warn"), width=1)
    d.text((x + 16, y + 16), "No option is chosen yet. Next stays greyed out "
                             "until you pick one.", font=f(11), fill=c("warn"))
    button(d, SIDEBAR + 24, H - 54, "Back", "ghost", 90)
    button(d, W - 250, H - 54, "Cancel", "ghost", 90)
    button(d, W - 146, H - 54, "Next", "ghost", 122)
    return im


def s_user():
    im, d = chrome(4)
    heading(d, "Your account", "The name and password you will use")
    x = SIDEBAR + 34
    rows = [("What is your name?", "Dad", False),
            ("Name for this computer", "bashan-laptop", False),
            ("Choose a password", "••••••••", True),
            ("Type it again", "••••••••", True)]
    y = 112
    for label, val, _ in rows:
        d.text((x, y), label, font=f(12), fill=c("text_dim"))
        d.rounded_rectangle([x, y + 20, W - 48, y + 60], radius=8,
                            fill=c("bg_void"), outline=c("border"), width=1)
        d.text((x + 14, y + 32), val, font=f(13), fill=c("text"))
        y += 80
    d.ellipse([x, y + 4, x + 16, y + 20], outline=c("ok"), width=2)
    d.text((x + 26, y + 2), "At least 6 characters. Both entries match.",
           font=f(11), fill=c("ok"))
    footer(d)
    return im


def s_summary():
    im, d = chrome(5)
    heading(d, "Check before installing",
            "Nothing has been changed yet. This is the last step you can stop at.")
    x = SIDEBAR + 34
    d.rounded_rectangle([x, 118, W - 40, 420], radius=10, fill=c("bg_deep"),
                        outline=c("warn"), width=1)
    d.text((x + 18, 134), "These changes will be made to",
           font=f(12), fill=c("text_dim"))
    d.text((x + 18, 154), "Samsung SSD 860 EVO  500 GB  (/dev/sda)",
           font=f(14, True), fill=c("text"))
    d.text((x + 18, 182), "which currently contains  Windows 11",
           font=f(12), fill=c("text_dim"))
    d.line([(x + 18, 206), (W - 58, 206)], fill=c("border_soft"))
    items = [("Keep", "Windows 11  —  /dev/sda1 and /dev/sda2, 240 GB, untouched", "ok"),
             ("Shrink", "/dev/sda2 from 460 GB to 240 GB", "warn"),
             ("Create", "a 512 MB boot partition  and  a 220 GB partition for Bashan OS", "ok"),
             ("Install", "the boot menu so you can choose Bashan OS or Windows 11", "ok")]
    y = 218
    for verb, text, kind in items:
        col = c("ok") if kind == "ok" else c("warn")
        d.text((x + 18, y), verb, font=f(12, True), fill=col)
        wrap(d, text, x + 100, y, W - x - 140, f(12), c("text"), 17)
        y += 44
    d.text((x + 18, 386), "Nothing else on this disk is touched.",
           font=f(12), fill=c("ok"))
    wrap(d, "When you press Install, you will be asked once more to confirm.",
         x, 436, W - x - 40, f(12), c("text_dim"))
    button(d, SIDEBAR + 24, H - 54, "Back", "ghost", 90)
    button(d, W - 250, H - 54, "Cancel", "ghost", 90)
    button(d, W - 146, H - 54, "Install", "primary", 122)
    return im


def s_installing():
    im, d = chrome(6)
    slide = Image.open(BR / "slide-bg.png").convert("RGBA").resize(
        (W - SIDEBAR - 68, 300), Image.LANCZOS)
    im.alpha_composite(slide, (SIDEBAR + 34, 40))
    d = ImageDraw.Draw(im)
    x = SIDEBAR + 34
    t = "Thirteen languages, written the right way round"
    tw = d.textlength(t, font=f(19, True))
    d.text((x + (slide.width - tw) / 2, 140), t, font=f(19, True), fill=c("text"))
    sub = ("Arabic, Hebrew, Syriac, Sorani and Persian read right to left, "
           "and Bashan OS lays itself out to match.")
    wrap(d, sub, x + 50, 180, slide.width - 100, f(12), c("text_dim"))
    for i in range(4):
        col = c("accent") if i == 2 else c("border")
        d.ellipse([x + slide.width / 2 - 34 + i * 20, 300,
                   x + slide.width / 2 - 26 + i * 20, 308], fill=col)
    d.text((x, 374), "Copying files…", font=f(13), fill=c("text"))
    d.rounded_rectangle([x, 400, W - 48, 416], radius=8, fill=c("bg_void"),
                        outline=c("border"), width=1)
    d.rounded_rectangle([x, 400, x + int((W - 48 - x) * 0.46), 416], radius=8,
                        fill=c("accent_deep"))
    d.text((x, 426), "46%  —  about 6 minutes left", font=f(11), fill=c("text_dim"))
    d.line([(SIDEBAR, H - 66), (W, H - 66)], fill=c("border_soft"))
    button(d, W - 146, H - 54, "Cancel", "ghost", 122)
    return im


def s_finished():
    im, d = chrome(7)
    logo = Image.open(BR / "logo.png").resize((110, 110), Image.LANCZOS)
    im.alpha_composite(logo, (SIDEBAR + (W - SIDEBAR) // 2 - 55, 70))
    d = ImageDraw.Draw(im)
    x = SIDEBAR + 34
    t = "All done"
    tw = d.textlength(t, font=f(26, True))
    d.text((SIDEBAR + (W - SIDEBAR) / 2 - tw / 2, 200), t, font=f(26, True),
           fill=c("text"))
    wrap(d, "Bashan OS is installed on this computer. Take out the USB stick "
            "and restart. You will be asked whether to start Bashan OS or "
            "Windows 11 each time you switch the computer on.",
         x + 30, 250, W - x - 100, f(13), c("text_dim"), 22)
    d.rounded_rectangle([x + 30, 350, x + 60, 380], radius=6, fill=c("accent_deep"),
                        outline=c("accent"), width=1)
    d.text((x + 74, 357), "Restart now", font=f(13), fill=c("text"))
    button(d, W - 146, H - 54, "Done", "primary", 122)
    return im


def sheet(name, screens, labels):
    pad, cols = 18, 2
    rows = (len(screens) + 1) // cols
    sw, sh = W + pad * 2, H + pad * 2 + 26
    out = Image.new("RGBA", (sw * cols, sh * rows), c("bg_void"))
    d = ImageDraw.Draw(out)
    for i, (im, lab) in enumerate(zip(screens, labels)):
        cx, cy = (i % cols) * sw + pad, (i // cols) * sh + pad + 24
        d.text((cx, cy - 22), lab, font=f(13, True), fill=c("accent"))
        out.alpha_composite(im, (cx, cy))
        d.rectangle([cx, cy, cx + W, cy + H], outline=c("border_soft"))
    out.convert("RGB").save(OUT / name)
    print(f"   build/previews/{name}")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sheet("08-installer-a.png",
          [s_welcome(), s_location(), s_keyboard(), s_disk()],
          ["1. Welcome — language, big text",
           "2. Location",
           "3. Keyboard",
           "4. DISK SETUP — nothing pre-selected, dual boot first"])
    sheet("09-installer-b.png",
          [s_user(), s_summary(), s_installing(), s_finished()],
          ["5. Your account",
           "6. CONFIRMATION — names the drive and what is on it",
           "7. Installing — Bashan slideshow",
           "8. Finished"])


if __name__ == "__main__":
    main()
