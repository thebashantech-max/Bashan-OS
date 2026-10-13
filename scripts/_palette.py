#!/usr/bin/env python3
"""Shared palette loading for the Bashan generators.

Both variants carry the same token names, so a generator reads either one
with no special case. Importing this module is how a generator becomes
light/dark aware:

    from _palette import VARIANTS
    for v in VARIANTS.values():
        ...  v.pal["bg_base"] ...  v.scheme  ...  v.suffix ...

Run this file directly to check the palettes against WCAG contrast minimums.
That check exists because a light theme fails in exactly one way: a colour
picked for a dark background stays in the file and becomes unreadable text.
The dark-mode accent #22d3ee measures 1.65:1 on white, so it cannot simply
be reused.
"""
import json
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


@dataclass(frozen=True)
class Variant:
    name: str          # "dark" | "light"
    pal: dict          # the palette tokens
    scheme: str        # Plasma colour-scheme name
    desktoptheme: str  # Plasma desktop-theme id
    lookandfeel: str   # look-and-feel package id
    suffix: str        # filename suffix ("" for dark)

    @property
    def is_light(self) -> bool:
        return self.name == "light"


def _load(fn: str) -> dict:
    return json.loads((ROOT / "theme" / fn).read_text())


VARIANTS = {
    "dark": Variant("dark", _load("palette.json"),
                    "Bashan", "Bashan", "com.bashan.desktop", ""),
    "light": Variant("light", _load("palette-light.json"),
                     "BashanLight", "Bashan-Light",
                     "com.bashan.desktop.light", "-light"),
}

DARK = VARIANTS["dark"]
LIGHT = VARIANTS["light"]


def rgb_tuple(h: str) -> tuple:
    h = str(h).lstrip("#")[:6]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def rgb_csv(h: str) -> str:
    return ",".join(str(c) for c in rgb_tuple(h))


def _lin(c: float) -> float:
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(h: str) -> float:
    r, g, b = (_lin(c) for c in rgb_tuple(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    """WCAG 2.1 contrast ratio between two hex colours."""
    la, lb = relative_luminance(a), relative_luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


# (foreground token, background token, minimum ratio, what it is)
CONTRAST_RULES = [
    ("text",       "bg_base",   7.0, "body text on a window"),
    ("text",       "bg_deep",   7.0, "text in a list or entry field"),
    ("text",       "bg_raised", 7.0, "text on a button"),
    ("text_dim",   "bg_base",   4.5, "secondary text"),
    ("text",       "accent_deep", 4.5, "text on a selected row"),
    ("accent",     "bg_base",   4.5, "links and active text"),
    ("accent_dim", "bg_base",   4.5, "visited links"),
    ("error",      "bg_base",   4.5, "error text"),
    ("ok",         "bg_base",   4.5, "success text"),
    ("warn",       "bg_base",   4.5, "warning text"),
    ("border_light", "bg_base", 1.6, "the dock's 1 px border against the shell"),
]


def check() -> int:
    bad = 0
    for v in VARIANTS.values():
        print(f"\n{v.name.upper()}  (scheme {v.scheme})")
        for fg, bg, floor, what in CONTRAST_RULES:
            r = contrast(v.pal[fg], v.pal[bg])
            ok = r >= floor
            bad += 0 if ok else 1
            print(f"  {'ok ' if ok else 'FAIL'} {r:5.2f} (min {floor:4.1f})  "
                  f"{fg} on {bg}  - {what}")
    if bad:
        print(f"\nE: {bad} contrast rule(s) failed")
    else:
        print("\nI: every contrast rule passes in both variants")
    return bad


if __name__ == "__main__":
    raise SystemExit(1 if check() else 0)
