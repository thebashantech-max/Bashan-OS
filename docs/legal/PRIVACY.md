# Privacy statement — Bashan OS 1.0

**DRAFT — not legal advice.** Prepared for review by a qualified lawyer.

Published by **Bashan Tech LLC**.

## The short version

**Bashan OS does not collect anything about you.** There is no account, no
registration, no product key, no usage reporting, no crash reporting to us,
and no identifier assigned to your computer. We do not run a server that
your computer talks to. We could not tell you how many people use Bashan OS,
because we have no way of knowing.

That is not a promise about every program on it. **Some of the programs
Bashan OS includes do connect to the internet**, because that is what they
are for. Below is the full list, measured from the built system rather than
assumed.

## What we removed

The build deliberately purges the usual reporting packages and **fails if
any of them survive**: `popularity-contest`, `apport`, `whoopsie`,
`ubuntu-report`, `reportbug`. KDE's own usage statistics (`KUserFeedback`)
are pinned to level 0 — send nothing — system-wide.

## What connects out, and when

### Always, as part of normal operation

| What | Where | Why | Can you turn it off? |
|---|---|---|---|
| **System updates** (`apt`) | `deb.debian.org`, `security.debian.org` | fetch security fixes | Yes, but you should not. Your IP address is visible to the mirror, as with any download. |
| **Brave's update channel** | `brave-browser-apt-release.s3.brave.com` | keeps the browser patched | Yes, by removing the repository — not recommended. |
| ~~Google's repository~~ | — | **Nothing. Shipped disabled.** See below. | n/a |
| **Clock** | `*.debian.pool.ntp.org` | sets the time | Yes, in System Settings. |

> ### About `dl.google.com` — nothing, unless you ask
>
> Google Chrome is not installed, and **Google's software repository is
> shipped switched off**. The file is there, named
> `google-chrome.list.disabled`, and apt only reads files ending in `.list`.
> **So a machine that never installs Chrome never contacts Google at all.**
>
> This changed in Part E. Earlier builds preconfigured the repository
> enabled, which meant every update check contacted `dl.google.com` even for
> users who never wanted Chrome.
>
> If you choose to install Chrome, the installer first shows you a dialog
> that says, in your own language, that doing so switches on Google's
> software source, that your computer will then contact Google regularly
> even when you are not using Chrome, and that removing Chrome switches it
> off again. **Only after you agree does anything change.**
>
> If you later remove Chrome, the repository is switched off again
> automatically and the one-click installer comes back.

### Only when you use the thing

| Program | Contacts | What it is for |
|---|---|---|
| **Brave** | websites you visit; Brave's own services for Shields lists, safe-browsing data and updates | being a web browser |
| **Thunderbird** | your mail provider, and only that | mail, calendar, contacts |
| **Discover** (software centre) | Debian's archive; **Flathub** if you enable it | installing programs |
| **Weather widget** | its weather provider, which receives the location you set | showing the weather |
| **The Bashan app** | `bashan.app` and its backend | it is a web application in its own window |
| **Google Chrome**, if you install it | Google | Google's own privacy policy applies, not ours |

### Switched off by us, though the program can do it

Measured by scanning each shipped binary, not assumed:

| Program | What it would do | What we did |
|---|---|---|
| **GIMP** | checks `https://www.gimp.org/gimp_versions.json` for new releases | turned off in the default configuration |
| **Converseen** | checks `converseen.fasterland.net` and `fasterland.net` for updates | turned off — **best effort; see the caveat** |
| **VLC** | looks up album art and track metadata online; asks about it on first run | turned off, and the first-run question suppressed |
| **Kdenlive, KolourPaint, HandBrake** | no update or telemetry address found in the shipped files | nothing needed |

**Caveat on Converseen:** the two settings used to disable its update check
were read out of the program's binary, not confirmed by running it and
inspecting the file it writes. It is possible that a version check still
happens when Converseen starts. This is flagged rather than claimed, and is
listed in `BLOCKS-PUBLIC-RELEASE.md`.

## What stays on your computer

The welcome application stores whether to show itself again
(`~/.config/bashan-welcome.conf`) and which theme you chose
(`~/.config/bashan-theme`). Both are plain files in your own home folder.
**Neither is sent anywhere. We never see them.**

## Children

Bashan OS has no account system, collects nothing, and is not directed at
children. **If it is ever supplied to a school, children's-privacy law may
apply to that supply even though the software collects nothing.** See
`BLOCKS-PUBLIC-RELEASE.md`.

## Your rights

Because we hold no personal data about you, there is nothing for us to show
you, correct, or delete. If that changes — if we ever add a website account,
an update service, or analytics — **this statement must be rewritten before
that ships**, and a lawyer must review it.

## Contact

Bashan Tech LLC — *(address and contact to be inserted before publication)*
