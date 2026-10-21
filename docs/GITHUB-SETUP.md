# GitHub repository settings — ready to paste

Everything here is text to copy into GitHub's own fields. Nothing in this
file does anything by itself.

Fill in `GITHUB_USER_HERE` wherever it appears.

---

## Repository description

GitHub's "Description" box, under the repo name. 350 characters maximum;
this is 139.

```
A bloat-free desktop Linux built from Debian 13 and KDE Plasma 6. Public Preview — tested on one laptop and in VMs, not for critical systems.
```

---

## Website field

```
https://bashan.app
```

---

## Topics

GitHub's "Topics" field. Paste them one at a time, or all at once in the
edit box:

```
linux debian debian-derivative kde plasma live-build calamares iso
desktop-linux distro linux-distribution bootable-iso secure-boot
```

---

## Social preview blurb

For the "Social preview" image caption, or for posting a link:

> **Bashan OS 1.0 — Public Preview**
> A desktop Linux built from Debian 13 with KDE Plasma 6. Office, browser,
> mail, photos, music, plus programming and teaching tools — installed and
> working out of the box. Boots with Secure Boot on. Tested on one laptop
> and in virtual machines: treat it as a preview, not a daily driver.

Shorter, for a post:

> Bashan OS 1.0 Public Preview is out — a Debian 13 / KDE Plasma 6 desktop,
> built to be usable the moment it boots. One laptop and a lot of VM testing
> so far, so: try the USB stick, back up first, and tell me what breaks.

---

## Settings to check after creating the repo

| Setting | Value | Why |
|---|---|---|
| Visibility | **Private** at first | Review it before the world sees it |
| Issues | On | It is how hardware reports arrive |
| Discussions | Off to begin with | One person cannot moderate two places |
| Wiki | Off | The docs live in `docs/` and are versioned with the code |
| Projects | Off | Not needed yet |
| Default branch | `main` | Already is |
| **Allow forking** | On | The MIT licence invites it; the brand assets are excluded in `LICENSE` |

### Branch protection — worth doing before it goes public

Settings → Branches → Add rule for `main`:

- Require a pull request before merging — **off** while you are the only
  author; it will only slow you down.
- **Do not allow force pushes** — **on**. This is the one that matters. It
  stops an accidental `push --force` from destroying the published history.

### Security

Settings → Code security:

- **Secret scanning** — on. It is free on public repositories and would have
  caught a committed key.
- **Dependabot alerts** — on, though this repository has almost no
  dependencies to alert about.

---

## The README's first impression

`README.md` already opens with the Public Preview warning. GitHub shows it
immediately under the file list, so anyone landing on the repository sees the
honest status before they see a download link. Leave it that way.

---

## Authorship — already settled

Every commit carries one identity:

```
Bashan Tech LLC <252811763+thebashantech-max@users.noreply.github.com>
```

A GitHub `noreply` address, so no personal mailbox is exposed to scraping.
This was done by rewriting history on 2026-10-20, before the first push.
**Do not rewrite it again once the repository is public** — it breaks every
clone anyone has made.
