# Download Bashan OS 1.0

**Public Preview — not for critical systems.**

This is an early release. It has been tested on one laptop and in virtual
machines. Treat it as something to try, not something to rely on.

---

## Before you start

**Back up your files first.** Installing an operating system can erase a
disk. If the only copy of your photos, documents or work is on the computer
you are about to install onto, copy them somewhere else first — another
computer, an external drive, or cloud storage. Do this even if you only
intend to try the USB stick without installing.

---

## Download

| | |
|---|---|
| **Archive.org** | `https://archive.org/details/bashan-os-1-0-public-preview` |
| **GitHub** | `https://github.com/thebashantech-max/Bashan-OS` |
| **File** | `Bashan-OS-1.0-amd64-public.hybrid.iso` |
| **Size** | 3,339,059,200 bytes (about 3.1 GB) |

**SHA256**

```
2f7a2c5224762176ee152b4c966d358086e1241924a9274fbab55bdf13d67727
```

---

## What you need

| | |
|---|---|
| A 64-bit PC | Intel or AMD. Not a Mac with an Apple chip, not a Raspberry Pi. |
| Memory | 4 GB minimum |
| Disk space to install | 40 GB |
| A USB stick | 4 GB or larger — **everything on it will be erased** |
| Secure Boot | Supported. You do not need to turn it off. |

---

## Step 1 — check the file is intact

A download can be damaged in transit, or be the wrong file. Always check.

**Windows** (PowerShell):

```powershell
Get-FileHash .\Bashan-OS-1.0-amd64-public.hybrid.iso -Algorithm SHA256
```

**macOS:**

```bash
shasum -a 256 Bashan-OS-1.0-amd64-public.hybrid.iso
```

**Linux:**

```bash
sha256sum Bashan-OS-1.0-amd64-public.hybrid.iso
```

Compare the result with the SHA256 above. It must match character for
character. **If it does not match, delete the file and download it again.**
Do not write a file that fails this check.

---

## Step 2 — write it to a USB stick

### The easy way: Balena Etcher

Works on Windows, macOS and Linux, and is the safer choice because it will
not offer you your own hard disk by mistake.

1. Download Etcher from <https://etcher.balena.io/>
2. Open it, choose **Flash from file**, and pick the ISO.
3. Choose your USB stick. **Check the size and name — make sure it is the
   stick and not your hard disk.**
4. Click **Flash**, and wait. It will verify the result by itself.

### The command-line way: dd (Linux or macOS)

Only if you are comfortable with a terminal. `dd` has no undo, and naming
the wrong device erases it.

First, find the stick:

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,RM,MOUNTPOINTS
```

Look for the line with `TRAN=usb` and `RM=1`, and check the size matches
your stick. Say it is `/dev/sdX` — **replace `sdX` with the real name, and
check it twice.**

Unmount anything on it, then write:

```bash
sudo umount /dev/sdX* 2>/dev/null
sudo dd if=Bashan-OS-1.0-amd64-public.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Then read it back and confirm it wrote correctly:

```bash
sudo head -c 3339059200 /dev/sdX | sha256sum
```

That must print the same SHA256 as above.

---

## Step 3 — boot from it

1. Put the stick in the computer and turn it on.
2. Press the boot-menu key as it starts — usually **F12**, sometimes **F9**,
   **F10**, **Esc** or **F2**. It is often shown on screen for a second.
3. Choose the USB stick from the list.

You will reach a desktop without installing anything. Nothing on the computer
is changed until you choose to install.

**Try it from the stick first.** Check that Wi-Fi works, that sound works,
that the screen looks right. If something is broken there, it will be broken
after installing too.

---

## Step 4 — install, if you want to

There is an **Install Bashan OS** entry in the menu. The installer asks for
your language, location, keyboard, where to install, and a username and
password.

On the disk page **nothing is selected by default** — you have to choose.
"Erase disk" deletes everything on the drive you pick. The installer shows a
confirmation before it changes anything.

---

## If something goes wrong

If you reach a black screen instead of a login prompt, press
**Ctrl + Alt + F2** for a text console — the system is probably running
normally underneath.

Report problems with: which computer, whether it was the USB stick or an
installed system, what you expected, and the SHA256 of the ISO you used.

---

*Bashan OS is built from Debian but is not a Debian product, and is not
endorsed by Debian, KDE, Brave, Google or Mozilla.*
