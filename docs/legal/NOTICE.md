# NOTICE — third-party software in Bashan OS 1.0

**DRAFT — not legal advice.** Prepared by the build process for review by a
qualified lawyer. Nothing here has been checked by one.

Bashan OS 1.0 is published by **Bashan Tech LLC**. It is built from Debian
GNU/Linux 13 ("trixie") plus a small amount of original work. The great
majority of what you receive is third-party free and open-source software,
supplied under its own licences by its own authors.

Figures below were measured from the actual built image
(`build/work/lb/chroot`) on 2026-10-12. The image at that point contained
**2,106 packages**. It does not yet include the Part A additions (VLC, GIMP,
Kdenlive, KolourPaint, Converseen, HandBrake), which are listed separately
and must be re-counted after the Part G rebuild.

## 1. Where the full licence texts are

Every package carries its own licence and copyright statement at

```
/usr/share/doc/<package>/copyright
```

on the installed system. **Those files are the authoritative terms.** This
notice summarises; it does not replace them, and nothing here overrides
them. The files are retained in full in the image, including for packages
whose licences require it.

## 2. The licences that cover most of the system

| Licence | Covers, among others |
|---|---|
| GPL-2.0 / GPL-2.0-or-later | the Linux kernel, GNU userland, KDE Plasma (`plasma-desktop`: GPL-2.0-or-later, measured) |
| GPL-3.0 / GPL-3.0-or-later | GIMP, Kdenlive, Converseen, much of the GNU toolchain |
| LGPL-2.1 / LGPL-3.0 | Qt 6, glibc, many libraries |
| MPL-2.0 | LibreOffice (measured), Thunderbird (MPL-2.0 or GPL-2 or LGPL-2.1, measured), **Brave** |
| BSD / MIT / Expat | large parts of the graphics and network stack |
| OFL-1.1 | the Noto, Scheherazade, Lateef and Amiri font families |
| Apache-2.0 | assorted components |

**Source code offer.** The GPL and LGPL require that source code be made
available to anyone who receives the binaries. Debian's source archive
satisfies this for every package taken unmodified from Debian. **A lawyer
must confirm whether distributing an ISO requires Bashan Tech LLC to make
its own written offer of source code, and in what form.** This is listed in
Bashan Tech LLC's internal legal notes (not published).

## 3. Components that are NOT free software

These matter most, because they are the ones with restrictions. Measured
from the image.

### 3.1 Non-free firmware — 36 packages

```
amd64-microcode  atmel-firmware  bluez-firmware  dahdi-firmware-nonfree
firmware-amd-graphics  firmware-ast  firmware-atheros  firmware-bnx2
firmware-bnx2x  firmware-brcm80211  firmware-cavium  firmware-cirrus
firmware-intel-graphics  firmware-intel-misc  firmware-intel-sound
firmware-ipw2x00  firmware-ivtv  firmware-iwlwifi  firmware-libertas
firmware-linux  firmware-linux-nonfree  firmware-marvell-prestera
firmware-mediatek  firmware-misc-nonfree  firmware-myricom
firmware-netronome  firmware-netxen  firmware-nvidia-graphics
firmware-nvidia-tesla-535-gsp  firmware-qlogic  firmware-realtek
firmware-siano  firmware-sof-signed  firmware-ti-connectivity
firmware-zd1211  intel-microcode
```

These are binary blobs loaded into network cards, graphics chips, sound
hardware and CPUs. Without them, Wi-Fi, Bluetooth and graphics do not work
on most laptops — which is why Debian 12 began including them on its own
installation media by default.

Each carries its own redistribution terms, in
`/usr/share/doc/<package>/copyright`. **Most permit redistribution of the
unmodified blob; some impose conditions.** A lawyer must confirm that every
one of the 36 permits redistribution in a product published under a third
party's name.

**Only 14 of these were asked for** in `packages/firmware.list.chroot`. The
other 22 arrived as dependencies of the `firmware-linux` metapackage. They
can be removed if their terms are a problem, at the cost of supporting less
hardware.

### 3.2 Other non-free packages — 4

| Package | What it is | Status |
|---|---|---|
| `fonts-xfree86-nonfree-syriac` | the Meltho Syriac fonts, © 2002 Beth Mardutho: The Syriac Institute | **see below** |
| `nvidia-detect` | reports which NVIDIA driver a card needs | reporting tool only |
| `libfishcamp1t64` | astronomy camera library | **nothing depends on it — see 3.4** |
| `libsbig4t64` | astronomy camera library | **nothing depends on it — see 3.4** |

### 3.3 The Syriac fonts, in detail

This one needs a decision, because it is the only non-free component that is
there to make a **language** work rather than hardware.

The Meltho licence grants, in its own words, permission "free of charge, to
any person obtaining a copy of these Fonts … to deal in the Font Software,
including without limitation the rights to use, copy, merge" and distribute.
**Redistribution is therefore expressly permitted.** What makes it non-free
in Debian's sense is a separate clause:

> The Font Software may not be modified, altered, or added to, and in
> particular the designs of glyphs or characters in the Fonts may not be
> modified.

Bashan OS ships the fonts unmodified, so on a plain reading this is
satisfied. It also requires that the name of Beth Mardutho not be used in
advertising without written authorisation, which we do not do.

**A free alternative is already installed.** `fonts-noto-extra` is in the
image and provides Noto Sans Syriac under the SIL Open Font License 1.1.
Syriac currently renders in Estrangelo Edessa (the non-free Meltho font)
only because `60-bashan-languages.conf` prefers it — it was chosen on
appearance, not necessity. Changing one line of fontconfig would make the
system fall back to the free Noto font and allow
`fonts-xfree86-nonfree-syriac` to be dropped entirely.

**Decision for the lawyer:** keep the Meltho fonts (better Syriac
typography, non-free but apparently redistributable unmodified), or drop
them for Noto Sans Syriac (unambiguously free, less refined). This is a
one-line change either way.

### 3.4 Three packages that should probably not be there at all

Measured: these are installed, and `apt-cache rdepends --installed` reports
**no installed package depends on any of them**.

| Package | Area | Problem |
|---|---|---|
| `firmware-b43-installer` | contrib | **Downloads Broadcom firmware from the internet at install time.** It does not contain the firmware; it fetches it. |
| `firmware-b43legacy-installer` | contrib | same |
| `b43-fwcutter` | contrib | the tool the above two use |
| `libfishcamp1t64`, `libsbig4t64` | non-free | astronomy camera libraries, unused |

The b43 packages are a **defect, not a decision**:
`packages/firmware.list.chroot` states in a comment that they are
"deliberately excluded: they DOWNLOAD firmware at install time, which fails
offline". They are nevertheless in the image, pulled in by a recommendation
rather than by our list. They are both a functional problem (the stated
target is a laptop installed from USB with no network) and a legal one (they
cause the user's machine to fetch firmware whose terms we have not reviewed
and do not control).

**Recommendation: remove all five.** Logged in Bashan Tech LLC's internal legal notes (not published).

## 4. Browsers

**Brave** is included, built from source released under the **MPL-2.0**, and
distributed from Brave Software's own apt repository, which the image keeps
configured so security updates keep arriving. A lawyer should confirm that
redistributing the official Brave binary — as opposed to the source — is
permitted, and separately that use of the Brave name and logo in a dock and
menu is within Brave's trademark policy.

**Google Chrome is deliberately NOT included.** The Chrome Terms of Service
state that without a separate written agreement you may not "reproduce,
duplicate, copy, sell, trade or resell the Services", and those terms cover
the executable build. No Chrome binary is in the ISO.

**Google's repository is shipped disabled**, as `google-chrome.list.disabled`
— apt reads only `.list` files, so an untouched machine never contacts
`dl.google.com`. Only the signing key is preinstalled, which contacts
nothing by itself. The repository is switched on only by the user accepting
a dialog that explains the consequence, and is switched off again
automatically if Chrome is later removed.

## 5. Applications added in Part A

Licences below are as stated by Debian; they are to be confirmed against
each package's own copyright file after the Part G rebuild.

| Application | Licence as packaged |
|---|---|
| VLC | GPL-2.0-or-later, with LGPL components |
| GIMP | GPL-3.0-or-later |
| Kdenlive | GPL-2.0-or-later / GPL-3.0 |
| KolourPaint | GPL-2.0 (KDE) |
| Converseen | GPL-3.0-or-later |
| HandBrake | GPL-2.0 |

All six come from Debian main. **Patent questions about the video formats
they handle are a separate matter** and are recorded in
Bashan Tech LLC's internal legal notes (not published).

## 6. Original work by Bashan Tech LLC

The following are original to this project and are **not** third-party
software: the Bashan name and logo, the wallpapers, the colour palettes and
themes, the icon theme (excluding the base icons it inherits), the Plymouth,
GRUB and SDDM themes, the welcome application, the installer branding, the
build scripts, and the translations of Bashan-specific strings.

The Trash icons are derived from artwork supplied by the owner.

**The boot song and the welcome music are of unconfirmed provenance** and
are excluded from any public release by a build guard. See
Bashan Tech LLC's internal legal notes (not published).

## 7. Trademarks

Debian, KDE, Plasma, Qt, LibreOffice, Thunderbird, Brave, Google, Chrome,
Flathub, VLC, GIMP, HandBrake and others are trademarks of their respective
owners. Bashan OS is not endorsed by, affiliated with, or sponsored by any
of them. Use of these names in menus, documentation and this notice is
nominative — to identify the software — but **a lawyer must confirm that
each use is within the relevant trademark policy**, Debian's and Brave's in
particular.
