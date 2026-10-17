# Part G — rebuild and QEMU test results

ISO: `Bashan-OS-1.0-amd64.hybrid.iso`, 3,061,235,712 bytes (2.9 GB)
SHA256: `33c74a7386926ba7e3ea0ff7bdbfa6c5c0ffed8d7577f960f5c9fdde3a322346`
Built 2026-10-17 16:02. 2,248 packages, 7,092.5 MB installed.

**Private test build. The boot song is included and its rights are
unconfirmed. Do not distribute this ISO.**

## It took four builds

| # | Outcome |
|---|---|
| 1 | **FAILED.** `--firmware-chroot true` made live-build explicitly install every firmware package in the archive; the Part E pins made those "no installation candidate", which apt treats as fatal. Also explains the Part D mystery of two unused non-free astronomy libraries: live-build installed them. |
| 2 | **FAILED.** `firmware-ipw2x00` asks for licence acceptance in its *pre-install* script; with nobody to ask it exits 2 and dpkg aborts. Preseeded. |
| 3 | **Built.** Tested — four more defects found (below). |
| 4 | **Built and tested.** |

## PASS

| Area | Evidence |
|---|---|
| UEFI boot, **Secure Boot ON** | boots to desktop |
| **ISO boot menu branded** | Bashan logo, "Bashan OS 1.0", wallpaper, "Bashan Tech LLC". **Zero Debian branding** |
| Plymouth splash | Bashan logo, cyan glow, black |
| Boot time | **7.629 s** = 3.139 s kernel + 4.490 s userspace |
| Welcome app | opens **automatically on first login**, 7 pages, "Show this at startup" correctly **unticked** |
| Welcome music | Mute button present, so the audio file loaded |
| Dock | floating pill, Bashan launcher left-most, all icons render |
| **Chrome placeholder icon** | fixed — `internet-web-browser`, no longer blank |
| Wallpaper | renders, cyan horizon glow |
| **Dark/light toggle** | `bashan-theme-toggle toggle` → light wallpaper, light dock, light titlebars, reported `Bashan theme: light` |
| **Firewall** | `ufw status` → **Status: active** |
| **tor daemon** | `systemctl is-enabled tor` → **masked** |
| **Auto security updates** | `unattended-upgrades` **enabled**, `apt-daily.timer` **enabled** |
| **Chrome repo disabled** | `/etc/apt/sources.list.d/` → `brave-browser.list`, `google-chrome.list.disabled` |
| **Syriac font** | `fc-match :lang=syr` → **Noto Sans Syriac** (the free font, as switched in Part E) |
| Arabic / Hebrew fonts | Noto Sans Arabic / Noto Sans Hebrew |
| **Hostname** | `bashan@bashan` — the `user@debian` leak is gone |
| Installer branding | "Bashan OS Installer", our logo, our step names, legible |
| **Installer safety** | nothing pre-selected, **Next greyed out**, "This will **delete** all data" in red, drive named `vda - 60.00 GiB (/dev/vda)` |
| All 7 build hooks | firewall, hardening, tor, Welcome Center removal, exclusions, firmware, Syriac — all asserted and passed |

## FAIL — one, not fixed

**Desktop widgets and the Trash icon.** Only the System Monitor appears, and
it is centred rather than placed. Weather, Notes and Trash are absent.

Diagnosed completely, against a live plasmashell:

1. `d.screenGeometry` is **undefined** on Plasma 6's containment. The
   correct call is the global `screenGeometry(screen)`; `screenGeometry(0)`
   returns `{"x":0,"y":0,"width":1280,"height":800,...}`. **Fixed.**
2. With that fixed, the script got further and then threw:
   `ReferenceError: Qt is not defined at line 34`. **`Qt.rect()` does not
   exist in Plasma's scripting environment.** It aborted the script, which
   is why only the one widget created before that line survived.
3. Replacing it with a plain `{x,y,width,height}` object raises **no error
   and has no effect** — the widget does not move.
4. Positions live in `ItemGeometriesHorizontal` in
   `plasma-org.kde.plasma.desktop-appletsrc`, which is **empty**, because
   scripted geometry never writes it.

**Conclusion: desktop applet geometry cannot be set through the Plasma 6
scripting API.** The remaining route is to write
`ItemGeometriesHorizontal` directly and restart plasmashell once at first
login. That is the thing the script's own comment set out to avoid, and it
is now the only option left.

The earlier version of this script wrote its "done" marker whenever the
D-Bus call returned 0 — which it does even when the script inside did
nothing — so the failure was recorded as a success and never retried. That
is fixed: it now logs plasmashell's reply and only records success when
plasmashell says it placed something. That log is what produced the
`Qt is not defined` diagnosis.

## NOT TESTED — be clear about this

None of the following was exercised. They are not passes.

- **Legacy BIOS boot** (UEFI+Secure Boot only this round)
- The **encryption checkbox** — appears only after choosing an automated
  option, which was not clicked
- **"Install alongside"** — still unproven; the fixture has no genuinely
  bootable OS
- **No installation was completed**, so there is still **no installed-system
  idle RAM, idle CPU or top-10 process list**. The 1,757 MB figure seen in
  the live session is page cache from the squashfs and must not be quoted
  as idle RAM
- Welcome app **buttons** and the `bashan-action:` handler
- Brave launching; the Bashan app's window class (`xprop`)
- The Chrome installer confirmation dialog
- Discover: opening, Flathub, search, sign-up prompts
- VLC, Gwenview, GIMP, Kdenlive, KolourPaint, Converseen, HandBrake opening
- File-type defaults in practice
- Tor Browser launcher entry; VPN import in the network applet
- `brave://policy`
- Screen lock
- **Arabic desktop in use**, and RTL dock mirroring
- Syriac text actually rendered on screen (the font resolves; no text shown)

---

# Trash design — tested, and it does NOT pass

Build 7, `d32c4ded72aea6c7406dd57f19c7a060b8b7b6d55255bb2d57cdc28e28da13cc`.

Alternative 1 was built as approved: a real `trash:/` link in `~/Desktop`,
shipped via `/etc/skel`, drawn by Folder View.

**One screenshot shows both answers at once** (`k-07-both-trash.png`), with
a real file in the trash:

| What | Position | Icon state | Verdict |
|---|---|---|---|
| The `.desktop` link (alternative 1) | top-left, as predicted | **EMPTY — wrong.** Never switches. | **FAIL** |
| The Trash **plasmoid** | wherever Plasma puts it (middle of the screen) | **FULL, with the approved variant-B glass artwork and "One item"** | correct icon, uncontrollable position |

## Why the link cannot work

A `Type=Link` `.desktop` file renders the icon named in its `Icon=` field.
That is a static string. Nothing re-reads the trash to change it. Verified
twice: with a real XDG trash entry present (`t.txt` plus its `.trashinfo`),
and again after forcing a desktop refresh. It stayed empty both times.

So the two properties you need cannot currently be had together:

- **Correct, switching artwork** → only the Trash plasmoid does this.
- **A chosen corner** → only the Folder View icon does this, and only the
  top corner.

## Position, measured

- **English:** top-left.
- **Arabic:** not yet tested, but Folder View mirrors with Qt's layout
  direction, so it should be top-right. **Not the bottom corners
  originally specified**, in either language.

## Honest recommendation

Ship the **Trash plasmoid**, not the desktop link. It is the only one that
shows the approved artwork in both states and switches by itself, which is
what was called critical. Accept that Plasma decides where it sits. The
user can drag it to a corner once, and Plasma remembers that.

The alternative - a desktop icon in a guaranteed corner that is **always
drawn empty** - looks like a bug to anyone who throws a file away.

---

# Trash plasmoid — tested, and it PASSES

Build 8, `4f971b87373d7cc31bcded5663d0be7e4f6a08e75b53d4c148f4527e044a1cea`.

## A correction to the previous entry

The earlier "the plasmoid does not switch" finding was **wrong, because the
test was wrong.** It created a trash entry by writing files into
`~/.local/share/Trash/` by hand. That is correct on disk per the XDG
specification, but it does not go through KIO, and KIO is what notifies the
widget.

Deleting a file the way a user actually does:

```
kioclient move ~/realfile.txt trash:/
```

switched the widget immediately, with no refresh.

## Results

| State | Mode | Result |
|---|---|---|
| Empty | dark | glass map, "Trash / Empty" — approved artwork |
| Full | dark | filled glass map, "Trash / One item" — approved artwork |
| Full | light | light re-cut artwork, reads clearly on the pale wallpaper |
| Empty | light | captured |

**Checksums: 16 of 16 approved trash icon files are byte-identical in the
ISO.** Both states, four sizes, both themes. Zero different, zero missing.

## Position — the known gap

The widget sits where Plasma put it, roughly the middle of the screen. **Not
a corner, and not mirrored for right-to-left.** No positioning is attempted
any more; the user drags it once and Plasma remembers.

Every promise of a corner has been removed: the welcome app's text in all 13
languages, `docs/DESIGN.md`, `docs/I18N.md`, and the preview mockup.
`docs/COMPATIBILITY.md` lists it as a known gap with the four approaches
that were tried and why each failed.
