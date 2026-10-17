# Stage 1 — full install in QEMU, UEFI with Secure Boot

ISO `4f971b87373d7cc31bcded5663d0be7e4f6a08e75b53d4c148f4527e044a1cea`,
40 GB blank target, Secure Boot ON, OVMF with Microsoft keys.

## Result: THE INSTALL FAILED

The installed system **does not boot**. The firmware found no boot device
and fell through to PXE.

## What DID work

| Step | Evidence |
|---|---|
| Installer launches, fully branded | screenshot |
| Partition page on a blank disk | only "Erase disk" and "Manual" offered, **nothing pre-selected, Next greyed out**, drive named `vda - 40.00 GiB (/dev/vda)` |
| **Encryption checkbox** | **present and UNTICKED** once "Erase disk" is chosen, alongside swap and filesystem choices |
| Users page | validates; hostname auto-generates as `bashan-x8664`; autologin **off** |
| **Confirmation screen naming the drive** | "**Erase disk /dev/vda (vda) and install Bashan 1.0**", full plan listed, button reads **Install** not Next |
| **Second confirmation dialog** | "You will not be able to undo these changes." — Install Now / Go Back |
| Slideshow | runs, shows our branded slides. This is the QML that had six duplicated translation blocks and would not have loaded before that fix |
| Partitioning | **GPT written**: EFI 537 MB fat32 with boot+esp flags, root 42.4 GB ext4 |
| File copy | **7.7 GB written to the disk** |

## What FAILED

**The EFI partition is completely empty.** `mdir` on it reports "No files":
no `/EFI`, no GRUB, no shim. So nothing was ever installed for the firmware
to boot.

The installer's sequence is correct - `bootloader` is present, immediately
after `grubcfg` - so the install **stopped before reaching it**. Progress
was last seen at 13%, "Filling up filesystems" (`unpackfs`). The window was
gone when the session was next seen, with no visible error.

Everything between `unpackfs` and `bootloader` is therefore suspect:
`machineid`, `fstab`, `locale`, `keyboard`, `localecfg`, `users`,
`displaymanager`, `networkcfg`, `hwclock`, `shellprocess@bashan`,
`services-systemd`, `grubcfg`.

**The Calamares log was in the live session and is gone.** Capturing it is
the first thing the next attempt must do.

## Two defects found along the way

### 1. The screen locker activated DURING the installation

Our Part E setting locks the screen after 10 minutes idle. An install takes
longer than that and needs no input, so the screen locked mid-install and
demanded a password.

**This is a bad bug independently of the install failure.** A
non-technical user starts an install, walks away, comes back to a password
prompt on a machine whose password is not yet set up. It may also be
implicated in the crash.

**Fix: the live session must not lock.** The idle lock belongs on the
installed system only.

### 2. The lock screen is unbranded

It shows a purple Debian wallpaper and the **Debian swirl logo**. A visible
Debian logo contradicts the branding requirement, and it appears at a
moment when the user is already confused.

## Not reached

Reboot into the installed system, first-login welcome app on the installed
system, installed idle RAM/CPU/top-10, GRUB menu, SDDM login. All of these
need an install that completes.
