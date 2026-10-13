# If an update breaks something — how to go back

Written in plain words on purpose. Nothing here needs the terminal.

## The short version

Bashan OS takes a **snapshot** of the system before it installs security
updates — but **only once you have switched snapshots on**. It cannot do
that for you, because it has to ask which disk to keep the snapshots on, and
that disk does not exist until Bashan OS is installed.

**Please do this once, on the day you install.** It takes two minutes and it
is the difference between a bad afternoon and a lost weekend.

## Switching snapshots on (do this once)

1. Open the menu with the Bashan button.
2. Type **Timeshift** and open it.
3. It asks for your password.
4. Choose **RSYNC** when it asks for a snapshot type. (Choose **BTRFS** only
   if you chose the btrfs filesystem when installing. If you are not sure,
   you did not — choose RSYNC.)
5. Choose the disk to keep snapshots on. Your main disk is fine. **A
   separate USB disk is better**, because a snapshot on a disk that dies
   dies with it.
6. For how many to keep, **5 daily** is a sensible answer.
7. Click **Finish**.

From then on, Bashan OS takes a snapshot before each round of security
updates, at most one a day.

## Going back to before an update

1. Open **Timeshift** from the menu.
2. You will see a list of snapshots with dates. The ones made by the system
   say *"Before Bashan OS security updates"*.
3. Click the one from **before the problem started**.
4. Click **Restore**.
5. Read the summary it shows you, then let it run. The computer restarts.

**Your documents, photos and files are not touched.** Timeshift restores the
system — the programs and settings — and leaves your home folder alone.
That is also why it is **not a backup**: it will not bring back a photo you
deleted.

## If the computer will not start at all

1. Switch it on and hold **Shift** (or tap **Esc**) to get the boot menu.
2. Choose **Advanced options**, then an **older kernel** version.
3. If it starts, open Timeshift and restore a snapshot as above.

## What this does not protect you from

- **A dead disk.** Snapshots on the same disk die with it.
- **A deleted file.** That is a backup's job, not a snapshot's.
- **A stolen laptop.** That is disk encryption's job.

**Keep a real backup of anything you cannot afford to lose, on something
that is not inside this computer.**
