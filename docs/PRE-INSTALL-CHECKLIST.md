# Before installing Bashan OS over the old prototype

The old prototype is already on this laptop, so this install **replaces a
working system**. Four things to settle first. Do not skip the first one.

## 1. His files — the only one that cannot be undone

- [ ] Has he put anything on this laptop **since** the prototype was
      installed? Photos, documents, downloads, anything.
- [ ] If yes: copy it to a USB disk **now**.
- [ ] **Open at least one file from the backup** and check it is really
      there. An unverified backup is not a backup.
- [ ] Note where the backup is, so it can be put back afterwards.
- [ ] Browser bookmarks and saved passwords — these live inside the browser
      profile and are easy to forget. Export them, or accept losing them.
- [ ] Email: if he used a mail program with POP (not IMAP), the mail is on
      this laptop only and will be erased.

**If anything on this list is unclear, stop and sort it out before going
further.** Everything else here is recoverable; this is not.

## 2. Which disk will be erased

- [ ] Does this laptop have **one** disk or more than one?
- [ ] Write down the size of the disk Bashan OS will go on, in GB.
- [ ] At the installer's partition page, confirm the device shown matches
      that size before choosing anything.
- [ ] If a USB disk is plugged in, **unplug it before installing.** The
      commonest way to erase the wrong disk is to have two plugged in.

The installer does not pre-select anything and keeps Next greyed out until
you choose — verified at Stage 9. The protection only works if you read the
device it names.

## 3. Dual boot — decide now, not at the partition page

- [ ] Is there another operating system on this laptop that must survive?
- [ ] If the answer is no (the prototype is all that is on it), **Erase
      disk** is the right choice and the simplest.
- [ ] If the answer is yes, stop: "Install alongside" has **not been proven
      to work** in this build. Stage 9 could not test it because the test
      disk had no genuinely bootable OS on it. Do not find out on his
      laptop.

## 4. Secure Boot

- [ ] Check the current state (`mokutil --sb-state`, or the firmware setup
      screen).
- [ ] Did the old prototype need Secure Boot turned **off** to boot?
- [ ] If it did, that was a limitation of the prototype. The new build ships
      Debian's Microsoft-signed shim and signed GRUB, and booted with Secure
      Boot **on** in QEMU at Stage 9.
- [ ] **Try the new USB with Secure Boot left ON first.** If it boots, leave
      it on — it is a real protection and turning it off is a downgrade.
- [ ] Only if it refuses to boot, turn it off, and tell me, because that
      would be a defect in the new build worth fixing.

## 5. Before clicking Install

- [ ] The laptop is **plugged into mains power**. An install that runs out
      of battery halfway leaves an unbootable machine.
- [ ] `docs/LAPTOP-TEST.md` has been run from the **live USB** of the new
      build, and Wi-Fi, sound, touchpad, brightness and sleep/wake all pass.
- [ ] You have 40 minutes and are not in a hurry.
- [ ] He knows the laptop will be unusable while it runs.

## Write down afterwards

- Which option you chose on the partition page.
- Whether Secure Boot was on.
- How long the install took.
- Anything that looked wrong, even slightly.

These go into `docs/HARDWARE-TEST-DAD-LAPTOP.md`.
