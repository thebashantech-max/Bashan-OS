# Security and performance — Part E

**Measured facts only.** Where something has not been measured, this says so
rather than estimating. Nothing here claims the system is "secure" or
"optimised": those are not properties that can be asserted, only evidence
that can be shown.

All measurements are from the built chroot of 2026-10-12
(`build/work/lb/chroot`), 2,106 packages, **6,925.7 MB installed**. Runtime
figures are from the Stage 9 QEMU run of the same build. Figures change with
the Part G rebuild.

## 1. Firewall — on, denying everything inbound

`hooks/chroot/0300-firewall.hook.chroot` sets, and then verifies:

| Setting | Value |
|---|---|
| `ENABLED` in `/etc/ufw/ufw.conf` | `yes` |
| `DEFAULT_INPUT_POLICY` | `DROP` |
| `DEFAULT_OUTPUT_POLICY` | `ACCEPT` |
| `DEFAULT_FORWARD_POLICY` | `DROP` |

Written as files rather than by running `ufw enable`, because inside a build
chroot ufw cannot reach the running kernel's netfilter and would fail. The
rules are applied by the `ufw` unit at first boot. GUI: **System Settings →
Firewall** (`plasma-firewall`, already installed).

**Not yet verified:** that `ufw status` reports active on a booted system.
Part G.

## 2. What actually listens — measured

| Port | Service | Exposure |
|---|---|---|
| 631/tcp | CUPS | **localhost only** — `Listen localhost:631` in `cupsd.conf` |
| — | `cups.socket` | local unix socket |
| 5353/udp | avahi-daemon | **listens on the network** |
| — | `uuidd.socket` | local unix socket |

**avahi-daemon is the only thing listening on the network**, and with the
firewall denying inbound, nothing reaches it from outside. Not installed, and
confirmed absent: `openssh-server`, `samba`, `nfs-kernel-server`, `rpcbind`,
`apache2`, `nginx`, `exim4`, `postfix`, `vsftpd`. The hardening hook **fails
the build** if `openssh-server` ever appears.

### Enabled services at boot — 30

```
accounts-daemon  apparmor  avahi-daemon  bashan-boot-sound  bluetooth
console-setup  cron  cups-browsed  cups  drkonqi-coredump-processor@
e2scrub_reap  getty@  grub-common  keyboard-setup  live-config  lm-sensors
ModemManager  networking  NetworkManager-dispatcher  NetworkManager
power-profiles-daemon  sddm  smartmontools  switcheroo-control
systemd-pstore  systemd-resolved  systemd-timesyncd  udisks2  ufw
wpa_supplicant
```

## 3. Vulnerability check on the package set

Ran `apt-get update` then `apt-get upgrade -s` against the real chroot with
the trixie security archive:

> **0 packages have a pending security update. 0 are upgradable from any
> origin.**

The package set is current with Debian security as of 2026-10-12. This means
no package is at a version Debian has published a fix for. **It does not
mean there are no vulnerabilities** — only that none is known-and-fixed and
still unapplied here. `cups-browsed` is at `1.28.17-6+deb13u1`, which carries
Debian's fixes for the 2024 remote-code-execution family.

Re-run this before every release; it is a snapshot, not a property.

## 4. Automatic security updates — on, and cannot reboot you

`unattended-upgrades`, configured in
`/etc/apt/apt.conf.d/51bashan-unattended`:

- **Only** `origin=Debian,codename=${distro_codename}-security`. Nothing
  else updates itself, so the system does not change under the user.
- `Automatic-Reboot "false"` and `Automatic-Reboot-WithUsers "false"`. The
  hardening hook **fails the build** if either is not false. Losing unsaved
  work to a surprise restart is worse than waiting hours for a kernel fix.
- Runs daily (`APT::Periodic`).

**Visible notification instead of a reboot:** a user timer
(`bashan-restart-notify`) checks hourly for `/run/reboot-required` and sends
one desktop notification — *"Security updates are installed. A restart will
finish applying them. There is no hurry."* A stamp file stops it nagging.
First check is 20 minutes after login, not at login, where a notification
competing with the desktop drawing itself is simply missed.

## 5. Pre-update snapshots

`/usr/libexec/bashan/pre-update-snapshot` runs as `ExecStartPre=-` of
`apt-daily-upgrade.service`.

**It does nothing unless the user has set Timeshift up**, and it is honest
about why: Timeshift must be told which disk to keep snapshots on, and that
disk does not exist at build time. The script exits 0 in every case — a
non-zero exit there would stop security updates installing, and a missing
snapshot is a smaller problem than an unpatched machine. At most one
snapshot per 20 hours, so an interrupted run cannot fill the disk.

Plain-words setup and rollback instructions: **`docs/ROLLBACK.md`**. The user
must do a two-minute setup once; that is unavoidable and is stated plainly
rather than hidden.

## 6. Disk encryption — optional, not pre-selected

`enableLuksAutomatedPartitioning: true` in `installer/modules/partition.conf`.

**Measured from the Stage 9 screenshot:** on arrival at the partition page
there is **no encryption checkbox visible and no option pre-selected** — the
three choices (Replace / Erase / Manual) all start empty and Next is greyed
out. In Calamares the encryption checkbox appears only after an automated
option is chosen, so this is consistent with it being optional.

**Not verified:** that the checkbox then appears, starts unticked, and what
warning Calamares' own passphrase UI gives. **Part G must click "Erase disk"
and screenshot it.**

**Calamares offers no supported configuration key for custom text on its
partition page.** The warning is therefore placed where we do control the
words — a new fifth slide in the installer slideshow, in all 13 languages:

> *"Write the password down now and keep it somewhere safe, away from this
> computer. There is no reset, no recovery and no back door. If you forget
> it, everything on this disk is gone for good — not even we can get it
> back."*

The slideshow runs during the file copy, which is after the passphrase is
chosen but still in time to write it down. That is the earliest point we can
reach without patching Calamares.

## 7. Hardening applied

| Item | What was done |
|---|---|
| Root login | No root password (`setRootPassword: false`); `passwd -l root` in the image. Admin is via sudo. |
| Remote login | No SSH server. **Build fails if `openssh-server` appears.** |
| sudo | `use_pty` (stops keystroke injection into a waiting sudo), `env_reset`, `secure_path`, `timestamp_type=tty`, 15-minute timeout, logging to `/var/log/sudo.log`, `pwfeedback` so non-technical users can see they are typing. Validated with `visudo -cf`. |
| Screen lock | 10 minutes idle, 5-second grace, lock on resume. System default; user can change it. |
| Kernel | `98-bashan-hardening.conf`: `kptr_restrict`, `dmesg_restrict`, `yama.ptrace_scope=1`, the four `fs.protected_*`, `rp_filter`, no ICMP redirects or source routing, `tcp_syncookies`, no broadcast ping, `log_martians`. |
| AppArmor | enabled (Debian default, confirmed in the service list). |

### Deliberately NOT set, and why

- **`kernel.unprivileged_userns_clone=0`** — would break the sandboxes in
  Brave and Chrome, and break Flatpak. A browser without its sandbox is far
  more dangerous than user namespaces are.
- **`kernel.yama.ptrace_scope=3`** — irreversible until reboot; breaks
  debuggers and crash handlers entirely. Scope 1 gives most of the benefit.
- **`kernel.kexec_load_disabled=1`** — breaks hibernation resume on some
  laptops.

## 8. Brave

`/etc/brave/policies/managed/bashan-privacy.json` (Chromium enterprise
policy) sets off: `MetricsReportingEnabled`, `BraveP3AEnabled`,
`BraveStatsPingEnabled`, `SafeBrowsingExtendedReportingEnabled`,
`UrlKeyedAnonymizedDataCollectionEnabled`, `SearchSuggestEnabled`,
`SpellCheckServiceEnabled`, `AlternateErrorPagesEnabled`,
`BackgroundModeEnabled`, `PasswordLeakDetectionEnabled`,
`PromotionalTabsEnabled`.

**Shields are left alone.** They are on by Brave's own default and there is
**no policy key that forces them on**, so claiming we enforce it would be
false.

**Not verified:** that Brave reads this file and the settings take effect.
Part G must open `brave://policy` and `brave://settings` and screenshot.

## 9. Runtime measurements

From the **Stage 9** QEMU run (2 vCPU, 2048 MB, KVM, virtio):

| Measurement | Value |
|---|---|
| Boot time | **6.93 s** (2.88 s kernel + 4.05 s userspace) |
| CPU at idle | **97–98% idle** |
| Memory, live session | 1399 MB of 1935 MB |

**The memory figure is not an idle-RAM figure and must not be quoted as
one.** A live ISO decompresses its squashfs into page cache as it runs, so
it always reports far more in use than the same system installed to disk.

**Still not measured, and cannot be from a live session:**

- idle RAM on an installed system
- the top 10 processes by memory at idle
- idle CPU on real hardware rather than KVM
- boot time on a spinning disk

All four need a completed installation. **Part G.**
