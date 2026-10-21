# Written offer of source code

Bashan OS is built almost entirely from software licensed under the GNU
General Public License and similar licences. Those licences require that the
corresponding source code be available to everyone who receives the binaries.
This file is how Bashan Tech LLC meets that obligation.

---

## 1. The offer

**Bashan Tech LLC hereby offers, to any third party who has received a copy
of Bashan OS, a complete machine-readable copy of the corresponding source
code for the GPL- and LGPL-licensed software it contains, on a medium
customarily used for software interchange, for a charge no more than the cost
of physically performing the distribution. This offer is valid for three (3)
years from the date on which you received the binary.**

To request it, write to:

> **admin@bashan.app**

Please include the **SHA256 checksum of the ISO you received**, so the exact
package versions can be identified. The checksum for each release is
published alongside the download, and is also recorded inside the running
system at `/usr/share/bashan/live-packages.txt`.

---

## 2. The faster way: Debian's own archive

Every package in Bashan OS except one is taken **unmodified** from Debian.
For those, the corresponding source is Debian's, and you can fetch it
immediately without asking anybody:

| Where | What it gives you |
|---|---|
| <https://sources.debian.org/> | Browse and download source by package and version |
| <https://snapshot.debian.org/> | The exact versions as they existed on the build date, kept permanently |
| `apt-get source <package>` | On any Debian trixie system |

The complete list of what is in a given ISO — every package, its version, its
source package and its declared licences — is in
[`docs/legal/PACKAGE-LICENSES.csv`](docs/legal/PACKAGE-LICENSES.csv),
generated from `dpkg` in the built image rather than from a wish list.

Use the **`source`** column when asking Debian for source: several binary
packages usually come from one source package.

---

## 3. What Bashan Tech LLC modified

Two things, and both are already public in this repository:

1. **Everything in this repository** — the build scripts, the live-build and
   Calamares configuration, the hooks, the package lists, the theme and the
   translations. Licensed under the MIT License; see [`LICENSE`](LICENSE).

2. **One patched upstream file:**
   `theme/shell-lockscreen/LockScreenUi.qml`, taken from Debian's
   `plasma-desktop-data` package and given Restart and Shut Down buttons.
   It remains under its original licence (LGPL-2.1+ / GPL-2+, as stated in
   `/usr/share/doc/plasma-desktop-data/copyright`), and the modified file is
   in this repository.

Nothing else in the image has been patched, recompiled or rebuilt by Bashan
Tech LLC.

---

## 4. Non-free firmware

The ISO contains 24 non-free firmware packages, plus `nvidia-detect` and
`torbrowser-launcher`. These are **not** free software and no source is
offered for them — their vendors do not publish it. Each is redistributable
only under its own terms, which are reproduced in the running system at
`/usr/share/doc/<package>/copyright`. They are listed by name and version in
[`docs/legal/PACKAGE-LICENSES.md`](docs/legal/PACKAGE-LICENSES.md).

---

## 5. If this offer is not honoured

If you ask for source under section 1 and do not receive it, that is a
licence violation and you should say so. The Software Freedom Conservancy
publishes guidance on how to pursue it:
<https://sfconservancy.org/copyleft-compliance/>

---

*Nothing in this file, in `LICENSE` or in `NOTICES.md` reduces any right that
the GPL, LGPL, MPL or any other licence grants you over the software it
covers. Where this file conflicts with such a licence, that licence wins.*
