# A Bashan apt repository — design only

**Nothing here is built. This is a proposal for you to approve or reject.**

The problem it solves: today, a Bashan OS machine receives Debian's security
updates automatically but can never receive **our** fixes. The SDDM black
screen that made three boots in four unusable was fixed in the ISO — every
machine installed from the older ISO is still broken, with no way to get the
fix short of reinstalling.

---

## 1. What is true today (measured, not assumed)

| | |
|---|---|
| `unattended-upgrades` | **enabled** |
| `apt-daily.timer`, `apt-daily-upgrade.timer` | **enabled** |
| Discover's update notifier | **deliberately disabled by us** (`Exec=/bin/true`, `NoDisplay=true`) |
| apt sources | Debian trixie `main contrib non-free non-free-firmware`, `trixie-security`, `trixie-updates`, plus Brave. Chrome ships as `google-chrome.list.disabled`. |

**What a non-technical user sees when updates exist: nothing at all.**
Security updates install silently in the background. Everything else
accumulates invisibly until they happen to open Discover themselves. There is
no tray icon, no prompt, no badge.

That is a defensible choice — it is quiet, and it avoids nagging — but it
means **we currently have no channel to reach our own users.**

Diversions were also tested: `base-files`, `plymouth`, `debconf`,
`plasma-desktop-data`, `sddm`, `im-config` and `plasma-discover` were all
reinstalled from Debian, and the Bashan branding survived every one —
`os-release`, the login avatar, the lock-screen buttons and the disabled
notifier all intact.

---

## 2. What becomes a package

Four `.deb`s, each small, each independently updatable:

| Package | Contains | Why separate |
|---|---|---|
| `bashan-branding` | os-release, Plymouth/GRUB/SDDM themes, the hand mark, wallpapers, icons, the login avatar, the diversions | Changes rarely; carries the proprietary artwork, so its licence differs from the rest |
| `bashan-welcome` | the welcome application and its translations | Changes often; the most likely thing to need a quick fix |
| `bashan-diagnostics` | the diagnostics window | Independent, rarely urgent |
| `bashan-desktop-config` | SDDM config, kscreenlockerrc, kxkbrc, the greeter watchdog, the install verifier | **The one that matters.** The SDDM fix would have shipped here. |

A fifth, `bashan-keyring`, holds the signing public key so the repository can
rotate keys without every user editing files by hand.

The ISO then installs these packages instead of copying files into the
rootfs. That is a real change to how the build works, and it is the bulk of
the effort.

---

## 3. How the repository is made

**Use `aptly`.** It handles snapshots and publishing cleanly, and it can
publish to a directory you then upload anywhere.

`reprepro` is simpler and lighter, but it has no snapshot model — you cannot
easily say "publish exactly what I tested last Tuesday" or roll back a bad
release. For something that updates other people's machines, that matters
more than simplicity.

```
aptly repo create -distribution=trixie -component=main bashan
aptly repo add bashan ../*.deb
aptly snapshot create bashan-2026-10-20 from repo bashan
aptly publish snapshot -gpg-key=<KEYID> bashan-2026-10-20
```

The output is a plain directory tree. It is static files — no server
software, no database, nothing to be compromised at runtime.

---

## 4. Signing

A GPG key signs the `Release` file. apt refuses anything that does not
verify.

- **Generate it offline**, on a machine that is not the build machine.
- **Back it up to two separate physical places**, encrypted. If you lose it,
  every installed machine stops accepting updates and the only fix is for
  each user to install a new keyring by hand.
- **Never put it on the build machine or in the repository.** Sign on the
  offline machine, or with a hardware token (a YubiKey works and keeps the
  key off disk entirely).
- Set an expiry — two years — so a forgotten key eventually stops working
  instead of being valid forever.
- The public half ships in `bashan-keyring`, installed to
  `/etc/apt/keyrings/bashan.gpg`, referenced by `signed-by=` in the sources
  file. Never use `apt-key`; it is deprecated and trusts the key for every
  repository on the machine.

---

## 5. Hosting

Static files, so free hosting is genuinely fine:

| Option | Notes |
|---|---|
| **GitHub Pages** | Free, no account needed by users, fine for a small repo. **Soft limits: 1 GB site, 100 GB/month.** Our packages are small, so this works — but it is a terms-of-service grey area for a package archive at scale. |
| **Cloudflare Pages** | Free, no bandwidth cap, faster. **This is the better choice** if the project grows. |

Either way the archive is served over HTTPS, and apt verifies the GPG
signature regardless — HTTPS protects privacy, the signature protects
integrity.

The ISO then ships:

```
deb [signed-by=/etc/apt/keyrings/bashan.gpg] https://apt.bashan.app trixie main
```

with a `bashan.sources` file in `/etc/apt/sources.list.d/`, and a DNS CNAME
from `apt.bashan.app` to whichever host, so hosting can change later without
touching installed machines.

---

## 6. The risks, plainly

**The signing key controls every machine running Bashan OS.** Anyone holding
it can publish a package that runs as root on every installed computer, at
the next automatic update, with no prompt. That is not a theoretical risk —
it is the ordinary consequence of how apt works, and it is why the key
handling above is strict.

| Risk | What it means | What reduces it |
|---|---|---|
| **Key theft** | Total compromise of every user's machine | Offline key or hardware token; never on the build machine |
| **Key loss** | No user can ever receive an update again | Two encrypted backups in different places |
| **A bad package** | A broken update bricks every machine at once, automatically, overnight | Test in a VM from a snapshot before publishing; stage to a `testing` component first |
| **Hosting disappears** | Updates silently stop; users never learn | Own the DNS name; monitor it |
| **You stop maintaining it** | Machines keep an apt source pointing at a dead or, worse, later re-registered domain | Keep the DNS registration even after the project ends |

The last one is worth saying twice: an abandoned apt source whose domain
lapses and is bought by someone else is a route into every machine that still
has it configured.

**A smaller, safer first step:** publish the packages but leave
`unattended-upgrades` applying **Debian security only**, so Bashan packages
need a deliberate action in Discover. Users would still get fixes, but a bad
Bashan package could not install itself overnight on every machine. Given
that the first thing this repository would have shipped is a fix for a bug
that made machines unusable, there is an argument both ways.

---

## 7. Steps to approve

1. **Decide whether to do this at all.** The alternative is "reinstall to get
   fixes", which for a preview with few users is honestly defensible.
2. Generate and back up the signing key offline. *(you)*
3. Register `apt.bashan.app` and point it at the host. *(you)*
4. Split the rootfs content into the four packages and change the build to
   install them. *(the real work — a week of care, not an afternoon)*
5. Set up aptly, publish a first snapshot containing only
   `bashan-desktop-config`, and test an upgrade in a VM from an ISO built
   before the fix.
6. Decide automatic-versus-prompted for Bashan packages.
7. Ship the sources file and keyring in the next ISO.

**Nothing in steps 4 to 7 should start before 2 and 3 are done**, because the
packaging work is wasted if the key handling is not settled first.
