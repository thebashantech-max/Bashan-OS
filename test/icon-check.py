#!/usr/bin/env python3
"""Guard the Trash artwork and the icon lookup that reaches it.

Two separate things have to hold, and only one of them is about the files.

1. The artwork must be the approved glass Syria-map set, byte for byte.
2. The icon theme must actually be able to RETURN it at whatever size the
   desktop asks for.

(2) is what failed in the live session. Every directory was Type=Fixed,
which matches an exact pixel size and nothing else, so a request for an
in-between size fell through to Inherits=breeze-dark and the desktop drew
Breeze's thin outline bin. The artwork was perfect and never used.
"""
import configparser, hashlib, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
THEMES = {"dark": ROOT / "theme/icons/Bashan-B", "light": ROOT / "theme/icons/_light"}
MAX = 512
fails = []

# --- the lookup -----------------------------------------------------------
for label, theme in THEMES.items():
    idx = theme / "index.theme"
    cp = configparser.ConfigParser(strict=False)
    cp.read(idx)
    by_context = {}
    for sec in cp.sections():
        m = re.match(r"^(\d+)x\d+/([A-Za-z0-9_-]+)$", sec)
        if not m:
            continue
        s = cp[sec]
        if s.get("Type") == "Fixed":
            fails.append(f"{label}: [{sec}] is Type=Fixed; in-between sizes fall back to breeze")
            continue
        try:
            lo, hi = int(s["MinSize"]), int(s["MaxSize"])
        except KeyError:
            fails.append(f"{label}: [{sec}] has no MinSize/MaxSize")
            continue
        by_context.setdefault(m.group(2), []).append((lo, hi, sec))

    for ctx, spans in by_context.items():
        spans.sort()
        covered = 1
        for lo, hi, sec in spans:
            if lo > covered:
                fails.append(f"{label}/{ctx}: sizes {covered}-{lo-1} match no directory "
                             f"(would fall back to breeze)")
            covered = max(covered, hi + 1)
        if covered <= MAX:
            fails.append(f"{label}/{ctx}: sizes {covered}-{MAX} match no directory")
        if not spans:
            fails.append(f"{label}/{ctx}: no directories at all")
    print(f"  {label}: {sum(len(v) for v in by_context.values())} directories, "
          f"contexts: {', '.join(sorted(by_context))}")

# --- the artwork ----------------------------------------------------------
approved = ROOT / "theme/icons/APPROVED-TRASH.sha256"
checked = 0
for line in approved.read_text().splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    want, path = line.split(None, 1)
    variant, size, name = path.split("/")
    f = THEMES[variant] / f"{size}x{size}" / "places" / f"{name}.png"
    if not f.is_file():
        fails.append(f"approved icon missing: {f.relative_to(ROOT)}")
        continue
    got = hashlib.sha256(f.read_bytes()).hexdigest()
    if got != want:
        fails.append(f"approved icon altered: {path}")
    checked += 1
print(f"  {checked} approved Trash icons checked")

if fails:
    print("\nI: icon check FAILED")
    for f in fails:
        print(f"  {f}")
    sys.exit(1)
print("I: artwork approved and reachable at every size from 1 to 512")
