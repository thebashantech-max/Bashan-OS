# Third-party notices

Bashan OS is assembled almost entirely from software written by other people.
This file names them, records their trademarks, and says how to get the source
code.

**Bashan OS is not endorsed by, affiliated with, or sponsored by any project
or company named here.** Every name below is used only to identify the
software it belongs to — which is what the software is, not who stands behind
Bashan OS. None of these projects has reviewed, approved or supported this
distribution.

The system also carries a longer notice at
`/usr/share/doc/bashan/legal/NOTICE.md`, generated from `docs/legal/NOTICE.md`.
That one is the authoritative per-package record; this file is the summary for
anyone reading the repository.

---

## Debian

Bashan OS is built from Debian GNU/Linux 13 ("trixie") using Debian's own
`live-build` tooling, and installs packages from Debian's archive. It is a
**derivative, not a Debian product**. Debian has not reviewed or endorsed it,
and problems with Bashan OS should never be reported to Debian.

"Debian" is a registered trademark of Software in the Public Interest, Inc.

Debian branding is removed from user-visible places in this derivative — the
wallpaper, the logos, the boot splash and `os-release` — precisely so that no
user mistakes this for Debian. Debian is named in documentation and in this
file to say truthfully where the software came from.

> **Open:** a lawyer must confirm this use fits Debian's trademark policy for
> a rebranded commercial derivative. See `docs/legal/BLOCKS-PUBLIC-RELEASE.md`
> §8.

## KDE

The desktop is KDE Plasma 6, with KDE Frameworks and many KDE applications
(Dolphin, Konsole, Gwenview, Okular, Kate, Discover, KWin, SDDM's Breeze theme
and others). They are supplied under the GPL, LGPL and other free licences by
the KDE community.

"KDE", "Plasma" and the KDE logo are trademarks of KDE e.V. KDE e.V. has not
endorsed Bashan OS.

Bashan OS ships a modified `LockScreenUi.qml` from
`plasma-desktop-data`, adding Restart and Shut Down buttons to the lock
screen. The modification is in this repository at
`theme/shell-lockscreen/LockScreenUi.qml` and is covered by the source offer
below.

## Qt

Plasma and many applications are built on Qt, supplied under the LGPL v3 by
The Qt Company and the Qt Project. "Qt" is a trademark of The Qt Company Ltd.

## Brave

Brave Browser is the default web browser. It is redistributed as the official
binary from Brave's own apt repository, under the Mozilla Public License 2.0
together with Brave's own terms for the binary build.

"Brave" and the Brave logo are trademarks of Brave Software, Inc. Brave
Software has not endorsed Bashan OS and does not support this distribution.

> **Open:** redistributing the official Brave binary, and using the Brave name
> and icon in the dock and menu, must be confirmed against Brave's trademark
> and redistribution policy. See `BLOCKS-PUBLIC-RELEASE.md` §8.

## Google and Chrome

Google Chrome is **not installed**. A menu entry offers to install it, and
only installs anything after the user agrees in a dialog. Google's apt
repository ships **disabled** and is enabled only by that agreement.

"Google" and "Chrome" are trademarks of Google LLC. Google has not endorsed
Bashan OS.

## Mozilla

Thunderbird is supplied under the Mozilla Public License 2.0. "Thunderbird"
and "Mozilla" are trademarks of the Mozilla Foundation.

## The Document Foundation

LibreOffice is supplied under the Mozilla Public License 2.0. "LibreOffice"
and "The Document Foundation" are trademarks of The Document Foundation.

## Others named in the system

VLC (VideoLAN), GIMP (GNOME Foundation / GIMP team), Inkscape, Audacity,
Blender, Kdenlive, LMMS, HandBrake, Godot, Geany, Flathub, Tor and The Tor
Project, WireGuard (Jason A. Donenfeld), OpenVPN, and the GNU Project and the
Linux kernel developers.

All trademarks are the property of their respective owners. None of these
projects endorses Bashan OS.

## Fonts

The system uses fonts under the SIL Open Font License 1.1, including Noto
fonts from Google and the DejaVu fonts. The GRUB theme's two `.pf2` files are
converted from a Debian-supplied font; that font's own licence applies to
them.

## Non-free firmware

The ISO contains **24 non-free firmware packages**, plus `nvidia-detect`
(non-free) and `torbrowser-launcher` (contrib), so that Wi-Fi, graphics and
other hardware work. These are **not** free software: each is redistributable
only under its own vendor terms, which are reproduced in the system at
`/usr/share/doc/<package>/copyright`.

Those 26 are listed by name and version in
`docs/legal/PACKAGE-LICENSES.md`, measured from the built image rather than
from the package lists. An earlier draft of this notice said 36; that number
came from an older build and was never re-measured.

**What these licences require of us.** The terms differ per vendor; these are
read from the copyright files in the built image, not assumed:

- **Intel microcode** (`intel-microcode`) permits redistribution in binary
  form **without modification**, provided we (1) reproduce Intel's copyright
  notice and disclaimer in the material accompanying the distribution, (2) do
  not use Intel's name to endorse or promote the product, and (3) do not
  reverse engineer, decompile or disassemble it. Condition 1 is met by
  shipping `/usr/share/doc/intel-microcode/copyright` in the image; **it is
  not met by this file alone**, so that path must stay present.
- **Some kernel firmware** is licensed to be redistributed **only as part of
  a kernel**. The image ships it exactly as Debian does, inside the firmware
  packages the kernel loads from, which is the form that permission
  contemplates. Extracting a blob and shipping it separately would not be.
- **AMD microcode and most others** follow the same binary-redistribution
  pattern with a notice-reproduction condition.

Condition 2 is the one to watch in marketing material: Bashan OS must not say
or imply that Intel endorses it.

One of them, `firmware-ipw2x00` (Intel PRO/Wireless), normally asks the person
installing it to accept Intel's licence. **This build answers yes in advance**,
because an unanswerable question aborts an automated build. That means Bashan
Tech LLC accepts Intel's licence on the user's behalf, silently. It is the
only package in the image that does this.

> **Open:** confirm that all 26 permit redistribution by a third party in a
> commercially published product, and decide whether pre-accepting Intel's
> licence is acceptable. See `BLOCKS-PUBLIC-RELEASE.md` §4c and §5.

---

## Written offer of source code

Most of Bashan OS is licensed under the GNU General Public License and similar
licences, which require that source code be available to everyone who receives
the binaries.

**For packages taken unmodified from Debian** — which is all but one of them —
the corresponding source is Debian's own, and is available from:

- `https://sources.debian.org/` (browse and download by package and version)
- `https://snapshot.debian.org/` (the exact versions as they were on the build
  date, preserved permanently)
- `apt-get source <package>` on any Debian trixie system

The exact versions in a given ISO are listed in the image at
`/usr/share/bashan/live-packages.txt`, and in this repository at
`docs/legal/PACKAGE-LICENSES.md`.

**For anything Bashan Tech LLC modified**, the modified source is in this
repository, under the licence in `LICENSE`.

**Written offer.** Bashan Tech LLC offers to supply, to any third party who
received a copy of Bashan OS, a complete machine-readable copy of the
corresponding source code for the GPL- and LGPL-licensed software it contains,
on a medium customarily used for software interchange, for no more than the
cost of performing the distribution. This offer is valid for three years from
the date the binary was distributed.

To request it, contact Bashan Tech LLC and give the SHA256 checksum of the ISO
you received, so the exact package versions can be identified.

> **Open:** a lawyer must confirm whether pointing at Debian's archive
> discharges the obligation for unmodified packages, or whether Bashan Tech
> LLC must host its own source archive, and must fill in a real contact
> address for the offer above. An offer with no address is not an offer. See
> `BLOCKS-PUBLIC-RELEASE.md` §10.

---

## Bashan Tech LLC's own work

The build scripts and configuration are under the licence in `LICENSE`. The
Bashan name, the hand mark, the wallpapers, the Trash artwork and the audio
are **not** open licensed and are excluded from it; see `LICENSE` section 2.

### The hand mark

The "OK hand" that appears in the boot menu, the startup splash, the login
avatar, the dock, the installer and the welcome window is the **brand mark of
Bashan Tech LLC**. It is also the Bashan app's logo and a Druze community
symbol, and Bashan Tech LLC is entitled to use it. Origin: **owner-confirmed,
2026-10-20.**

Drawing credited to: ________________________ *(to be filled in)*

It is **all rights reserved** and excluded from the open licence on the code.
It being present in a published ISO is a decision about distributing Bashan
OS, not permission for anyone else to use the mark. A fork must remove it and
supply its own; `PLACEHOLDER_ASSETS=yes` no longer does that for you, because
the mark is now intended to ship.
