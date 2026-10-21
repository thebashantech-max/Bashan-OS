# Publishing to GitHub — the exact steps

**Nothing in this file has been run.** These are commands for *you* to paste
into *your own* terminal. Claude Code has not pushed, created a repository,
or added a remote.

Fill in `GITHUB_USER_HERE` before you start.

---

## Before you do any of this

> ### `gh` is already logged in on this machine
>
> ```
> ✓ Logged in to github.com account thebashantech-max (keyring)
> ```
>
> That session was there before any of this work. It means **`gh repo create`
> will succeed immediately, with no password prompt and no confirmation.**
> There is no "are you sure" between you and a live repository. Read each
> command before you press Enter.
>
> If that is not the account you want to publish under, fix it first:
> ```bash
> gh auth status          # see which accounts are available
> gh auth switch          # change the active one
> ```

Three things are still unfilled and **should be decided before the first
push**, because changing them afterwards means rewriting history again:

1. **The contact email.** `CONTACT_EMAIL_HERE` appears in `SOURCE-OFFER.md`
   and `SECURITY.md`. A source offer nobody can reply to is not an offer.
2. **Commit authorship.** The history carries
   `Mike Hagari <your-github-email@example.com>` (51 commits) and
   `Bashan Tech LLC <thebashantech@gmail.com>` (12 commits). Both become
   permanently public.
3. **The history rewrite**, if you approve it — see
   `docs/legal/BLOCKS-PUBLIC-RELEASE.md` §12. Do that **before** pushing,
   never after.

---

## Step 1 — a last look at what will be published

```bash
cd ~/Bashan-OS-1.0
git log --oneline | head -20
git ls-files | wc -l
du -sh .git
```

Check the working tree is clean and nothing unexpected is tracked:

```bash
git status --short
git ls-files | grep -iE '\.(iso|img|wav|mp3)$'
```

That last command should print **nothing**. If it prints an audio file, stop
— the song must not be published.

---

## Step 2 — create the repository, PRIVATE

```bash
cd ~/Bashan-OS-1.0
gh repo create Bashan-OS \
  --private \
  --source=. \
  --remote=origin \
  --description "A bloat-free desktop Linux built from Debian 13 and KDE Plasma 6. Public Preview — tested on one laptop and in VMs, not for critical systems."
```

`--source=.` adds the remote for you. Confirm it:

```bash
git remote -v
```

You should see `origin` pointing at `https://github.com/GITHUB_USER_HERE/Bashan-OS.git`.

---

## Step 3 — push

```bash
git push -u origin main
```

Roughly 35 MB. If it is far larger, stop and check what is being sent.

---

## Step 4 — review it as a stranger would

Open `https://github.com/GITHUB_USER_HERE/Bashan-OS` and check:

- [ ] The README's "Public Preview — do not put this on a computer you
      depend on" warning is the first thing visible.
- [ ] `LICENSE` is detected, and says MIT with the brand assets excluded.
- [ ] `SOURCE-OFFER.md` and `SECURITY.md` have a **real email**, not
      `CONTACT_EMAIL_HERE`.
- [ ] No audio file anywhere — search the repo for `boot-song`.
- [ ] `docs/legal/BLOCKS-PUBLIC-RELEASE.md` — decide whether you want this
      public. It is an honest, detailed list of the project's own legal
      exposure: codec patents, trademark questions, export control. Publishing
      it is unusually transparent, and it is also a catalogue of where the
      project is weakest. **Your call, and worth making deliberately.**
- [ ] The commit author names and emails are ones you are happy to publish.

Apply the settings in `docs/GITHUB-SETUP.md` — topics, website, and
**disable force pushes** on `main`.

---

## Step 5 — make it public, when you are ready

```bash
gh repo edit GITHUB_USER_HERE/Bashan-OS --visibility public --accept-visibility-change-consequences
```

Or in the browser: **Settings → General → Danger Zone → Change visibility**.

> Once it is public, assume every commit has been cloned and archived within
> minutes. Deleting the repository afterwards does not retract anything.
> This is the point of no return — everything before it is reversible.

---

## Step 6 — the release itself

The ISO is 3.1 GB. **GitHub Releases caps a single file at 2 GB**, so the ISO
**cannot** be attached to a GitHub release. Host it on archive.org and point
to it:

```bash
gh release create v1.0-preview \
  --title "Bashan OS 1.0 — Public Preview" \
  --notes-file ~/bashan-release/RELEASE-NOTES.md \
  ~/bashan-release/SHA256SUMS
```

That publishes the notes and the checksum file only. Put the archive.org URL
into the release notes before you run it, and into `DOWNLOAD.md` for the
website.

---

## If you need to undo

Before anyone has cloned it — realistically, within minutes of going public:

```bash
gh repo edit GITHUB_USER_HERE/Bashan-OS --visibility private --accept-visibility-change-consequences
```

To remove the remote locally and go back to where you are now:

```bash
git remote remove origin
```

Neither undoes a clone someone already made. Treat Step 5 as permanent.
