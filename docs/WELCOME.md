# "Get to Know Bashan OS" — the welcome app

## What it costs

**0.1 MB.** One package, `qml-qt6`, which provides the `qml` runner. Every
module the app imports — QtQuick, Controls, Layouts, QtCore, QtMultimedia —
was already in the image for Calamares and Plasma.

| Toolkit | Measured marginal cost |
|---|---|
| **Plain QML + `qml-qt6`** | **0.1 MB** (1 package) |
| PyQt6 | 17.9 MB (3 packages) |
| PySide6 | 86.4 MB (10 packages) |

A trap worth recording: the `qml` runner is **not** in
`qt6-declarative-dev-tools`. That package ships `qmllint`, `qmlformat`,
`qmlls` and friends but no runtime. The runner is in `qml-qt6`, found by
grepping Debian's `Contents-amd64` index rather than by guessing.

## When it opens

- **First login only, by default.** `/etc/xdg/autostart/bashan-welcome.desktop`
  runs `bashan-welcome --autostart`, which creates
  `~/.config/bashan-welcome.seen` the first time and opens the app.
- On later logins it opens **only** if the user ticked "Show this when I
  start the computer", which writes `showAtStartup=true` to
  `~/.config/bashan-welcome.conf`. The box starts **unticked**, so the
  default really is once.
- Always reopenable from the launcher as **Get to Know Bashan OS**.

### It cannot block login

The `--autostart` path reads two small files and exits in milliseconds when
there is nothing to do. When there is, it waits four seconds so the desktop
has finished drawing, then starts the app and returns. Plasma does not wait
for autostart entries in any case, so even a hang could not hold up a login.

## It replaces KDE's Welcome Center

Stage 9 defect 5 was `plasma-welcome` opening on first boot.
`hooks/chroot/0910-no-kde-welcome.hook.chroot` **purges the package**.
Suppressing its autostart would have meant guessing how Plasma triggers it;
removing it cannot be got wrong. It is a Recommends of `plasma-desktop`, not
a Depends — `apt-get remove -s` reported exactly one package removed. The
hook then fails the build if `plasma-welcome` survived, or if our own app,
its catalogue or the `qml` runner is missing.

## Pages

1. The Bashan logo, the greeting, and the mute button for the music.
2. What Bashan OS is.
3. The tour: dock, the Bashan button, desktop panels, Trash, your programs.
4. Language, dark/light, and the startup sound.
5. Installing Google Chrome, and the software centre.
6. Privacy and legal, with buttons opening the three documents in
   `/usr/share/doc/bashan/legal/`.

## How the buttons work

QML cannot start a process. Three buttons need to run a command, so they
open a `bashan-action:` URL that `/usr/bin/bashan-action` carries out,
registered through `bashan-action.desktop` and `/etc/xdg/mimeapps.list`:

| Button | Action |
|---|---|
| Switch the look | `bashan-theme-toggle toggle` |
| Install Google Chrome | `bashan-install-chrome` |
| Play the startup sound | `pkexec /usr/libexec/bashan/bashan-set-boot-sound yes\|no` |

Two buttons need no helper at all: the software centre opens via the
`appstream:` scheme Discover registers itself, and the legal documents open
as ordinary `file://` URLs.

The startup-sound switch needs `pkexec` because
`/etc/bashan/boot-sound.conf` is root-owned — it controls something that
happens before any user logs in. `polkit-kde-agent-1` draws the password
prompt. The helper rewrites only the `ENABLED` line, so a user who pointed
`SONG=` at their own file keeps it.

## The music

Plays **once**, on page 1 only, never loops, with a visible mute button.
Leaving page 1 stops it for good; returning does not restart it.

**It is the same file as the boot song, so it ships under the same rights
guard.** `INCLUDE_BOOT_SONG=yes` with `PUBLIC_RELEASE=yes` makes the build
refuse to run. When the guard leaves the song out, the player reports
invalid media, `musicAvailable` is false and the mute button simply does not
appear — the app is otherwise unaffected.

### Swapping the file

Drop a WAV at **`/etc/bashan/welcome-song.wav`**. That path is tried first
and survives system updates, which `/usr/share` does not. Convert with:

```
ffmpeg -i yoursong.mp3 -ar 48000 -ac 2 -c:a pcm_s16le /etc/bashan/welcome-song.wav
```

### A CC0 replacement, if you want one

**Nothing has been downloaded.** These are suggestions to look at yourself:

| Source | Licence | Notes |
|---|---|---|
| **freesound.org**, filtered to **CC0 1.0** | CC0 1.0 Universal — public domain dedication, no attribution required | The safest option for an ISO you distribute. Filter explicitly on CC0; Freesound also hosts CC-BY and CC-BY-NC material, which is **not** equivalent. |
| **Free Music Archive**, "Public Domain" / CC0 filter | CC0 1.0 | Longer pieces; check each track's licence line, as FMA mixes licences. |
| **Pixabay** audio | Pixabay Content License | Royalty-free and no attribution, but it is **not** CC0 and it forbids redistributing the file "as-is" on its own. Usable inside an OS, but CC0 is cleaner. |

Pick something **four to six seconds long** to match the splash hold of 5.5 s
set in `config/build.conf`.

## Translations

41 strings in all 13 languages, 533 entries, generated from
`i18n/strings.json` into `/usr/share/bashan/welcome/i18n.json` by
`scripts/40-i18n.py`. The catalogue carries each language's confidence and
its right-to-left flag.

**The app says so itself.** On page 4, when the current language has not
been checked by a native speaker, it shows that language's confidence rating
on screen rather than letting the user assume the text is reviewed. Kurmanji
and Sorani are LOW, Syriac VERY LOW. `i18n/REVIEW.csv` now holds 732 rows
for review.

## Right to left

Verified by screenshot, not assumed: in Arabic the whole window mirrors —
headings right-aligned, the navigation buttons move to the left edge, the
checkbox indicator moves to the right of its label, and the Arabic text
shapes and joins correctly.

## What was found by running it

The app was screenshotted for real under Xvfb at every page, in English and
Arabic, dark and light. Three defects came out of that, none of which
reading the code would have caught:

1. **Every string rendered as its key.** Qt 6 disables `XMLHttpRequest` on
   `file://` URLs by default, so the translation catalogue never loaded. The
   launcher now sets `QML_XHR_ALLOW_FILE_READ=1`.
2. **The checkbox indicators were invisible** — the Basic style draws them
   from `palette.base` with a hairline border, which disappears on a dark
   surface. The app now ships its own indicator.
3. **Every control used the stock Basic palette**, putting near-black
   checkbox labels on the dark background and a white face on every button.
   Fixed by setting the window palette once, which all controls inherit.

`qmllint` reports **0 errors**; the only two remaining warnings are
`XMLHttpRequest` being an unqualified JavaScript global, which is expected.

## Known rough edge

On page 4 at the default 1000x720 window, the bottom border of the third
card sits just under the footer. The page scrolls, so nothing is
unreachable, and the checkbox itself is fully visible — but it is not as
tidy as the other pages. On a taller window it does not happen.
