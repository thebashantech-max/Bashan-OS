# Hardware record — old Zorin-based prototype (reference only)

**What this is:** a record of real hardware, filled in from a machine that
currently runs the **OLD Zorin-based prototype**, installed from USB.

> ### ⚠ This is NOT the new Bashan OS build
>
> The results below come from a different operating system — the earlier
> Zorin-based prototype. They are **hardware evidence**: they tell us which
> chips are in this laptop and which of them work under a Linux kernel.
> They are **not** a test of Bashan OS 1.0, and nothing here should be read
> as the new build passing anything.
>
> The new build has a **different kernel, a different firmware set and a
> trimmed firmware list**. Every chip below must be checked against
> `packages/firmware.list.chroot` and
> `config/archives/bashan-firmware-trim.pref.chroot` before Part G.

Last updated: 2026-10-13.

---

## 1. The machine

| Field | Value |
|---|---|
| Brand | **TO FILL** |
| Model | **TO FILL** |
| Model number / product code | **TO FILL** |
| Year / approximate age | **TO FILL** |
| CPU | **TO FILL** |
| CPU architecture | **TO FILL** (expect x86_64) |
| RAM installed | **TO FILL** |
| RAM type / slots free | **TO FILL** |
| Storage type | **TO FILL** (SSD or spinning disk — this changes boot time a lot) |
| Storage size | **TO FILL** |
| Storage free before install | **TO FILL** |

## 2. The chips that decide whether this works

| Field | Value | Firmware package needed |
|---|---|---|
| GPU | **TO FILL** | **TO FILL** |
| GPU kernel driver in use | **TO FILL** | — |
| Wi-Fi chip | **TO FILL** | **TO FILL** |
| Wi-Fi kernel driver in use | **TO FILL** | — |
| Bluetooth chip | **TO FILL** | **TO FILL** |
| Audio codec | **TO FILL** | **TO FILL** |
| Audio kernel driver in use | **TO FILL** | — |
| Ethernet | **TO FILL** | **TO FILL** |
| Webcam | **TO FILL** | — |
| Fingerprint reader | **TO FILL** | — |
| SIM slot / cellular modem | **TO FILL** (yes / no) | — |
| Card reader | **TO FILL** | — |

> The right-hand column is the point of this table. Each chip is matched
> against the firmware the new build ships, and anything missing is flagged
> **before** Part G rather than discovered on the laptop.

## 3. Screen and firmware

| Field | Value |
|---|---|
| Screen size | **TO FILL** |
| Screen resolution | **TO FILL** |
| Scaling needed | **TO FILL** |
| External display tested | **TO FILL** |
| Firmware type | **TO FILL** (UEFI or legacy BIOS) |
| **Secure Boot state** | **TO FILL** (enabled / disabled / not supported) |
| Secure Boot had to be turned off to boot the USB | **TO FILL** (yes / no) |

Secure Boot matters: the new build ships Debian's signed shim and GRUB and
booted with Secure Boot **on** in QEMU at Stage 9. If this laptop needed it
turned off for the old prototype, that was a limitation of the prototype,
not necessarily of the new build.

## 4. What was on it, and what happened to the files

| Field | Value |
|---|---|
| OS before the prototype | **TO FILL** |
| That OS still present (dual boot)? | **TO FILL** |
| **Were his files backed up first?** | **TO FILL** |
| Where is the backup | **TO FILL** |
| Backup verified by opening a file from it | **TO FILL** (yes / no) |
| Anything lost | **TO FILL** |

> If the backup answer is "no", say so plainly here. It changes what we do
> next far more than any hardware detail.

## 5. Pass / fail — on the OLD prototype

Fill `PASS`, `FAIL`, or `NOT TESTED`. Add a note for anything that half
works — "half works" is the most useful answer there is.

| # | Thing | Result | Notes |
|---|---|---|---|
| 1 | Wi-Fi — sees networks | **TO FILL** | |
| 2 | Wi-Fi — connects and loads a page | **TO FILL** | |
| 3 | Sound — laptop speakers | **TO FILL** | |
| 4 | Sound — headphone jack switches | **TO FILL** | |
| 5 | Sound — volume keys | **TO FILL** | |
| 6 | Touchpad — pointer, tap, two-finger scroll | **TO FILL** | |
| 7 | Keyboard — all keys correct | **TO FILL** | |
| 8 | Keyboard — special/function keys | **TO FILL** | |
| 9 | Brightness keys | **TO FILL** | |
| 10 | Bluetooth — finds and pairs a device | **TO FILL** | |
| 11 | Webcam | **TO FILL** | |
| 12 | Battery — shows charge and time | **TO FILL** | |
| 13 | Battery — rough runtime observed | **TO FILL** | |
| 14 | Sleep / wake — first time | **TO FILL** | |
| 15 | **Sleep / wake — second time** | **TO FILL** | some laptops only fail on the second |
| 16 | Fan noise at idle | **TO FILL** | |
| 17 | Heat at idle | **TO FILL** | |
| 18 | Arabic typing — keyboard layout switches | **TO FILL** | |
| 19 | Arabic — letters shape and join correctly | **TO FILL** | |
| 20 | Arabic — desktop mirrors right-to-left | **TO FILL** | |
| 21 | Brave — starts and loads pages | **TO FILL** | |
| 22 | Brave — video plays with sound | **TO FILL** | |
| 23 | Shutdown — completes, no hang | **TO FILL** | |
| 24 | Restart — completes | **TO FILL** | |

## 6. Anything else he noticed

**TO FILL** — in his words, not translated into technical language. "It
makes a noise when it wakes up" is a more useful bug report than most.

## 7. Collected files

Paste or attach the output of the collection commands in
`docs/HARDWARE-TEST-DAD-LAPTOP-raw.txt`.

| File | Collected? |
|---|---|
| `bashan-hardware-report.txt` | **TO FILL** |

## 8. Conclusions — filled in after the raw data arrives

| Question | Answer |
|---|---|
| Any chip whose firmware the new build does not ship | **TO FILL** |
| Any chip whose firmware the Part E trim removed | **TO FILL** |
| Anything that needs adding back before Part G | **TO FILL** |
| Is this laptop a good target for Bashan OS 1.0 | **TO FILL** |
