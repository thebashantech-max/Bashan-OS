# Contributing

Thanks for taking an interest.

## The most useful thing you can do

**Run it on your hardware and tell us what broke.** Bashan OS has been tested
on exactly one laptop and in virtual machines. Almost every real problem left
is one nobody has seen yet because nobody has run it on that machine.

A useful report says:

- which computer — make, model, and the graphics chip if you know it;
- whether it was the USB stick or an installed system;
- what you expected and what happened;
- the SHA256 of the ISO you used.

A photo of the screen is worth a lot, especially for anything that happens
before the desktop appears.

## Changing the code

The repository is build scripts and configuration — there is no application
source here to speak of. Before a change:

```bash
./build.sh test
```

That runs shellcheck, the colour-contrast check, and the self-tests for the
install verifier, the public-release guard, the EFI repair, the icons, the
wallpaper and the keyboard rule. **It has to pass.** Several of those tests
exist because something shipped broken once; please do not weaken one to get
a change through.

Then build an ISO and boot it. A change that only passes the tests is not
finished:

```bash
./build.sh config && ./build.sh build
```

`docs/BUILD.md` explains the stages.

## House style

- **Shell and Python, no new dependencies** unless there is no alternative.
- **Comments say why, not what.** The code says what.
- **When you fix something that shipped broken, write down how it failed**
  in a comment or a commit message. Much of this repository is that.
- Keep commits focused and describe the effect in plain words.

## What will be turned down

- Artwork changes. The hand mark, the name and the wallpapers are Bashan
  Tech LLC's and are not open licensed; see `LICENSE` section 2.
- Adding software to the ISO without a reason that survives "does every user
  need this?" — the image has a size budget.
- Anything that disables a safety check: the installer's partition defaults,
  the public-release guard, the install verifier.

## Licence

Code contributions are taken under the MIT License in `LICENSE`. By sending a
patch you confirm you wrote it, or that you have the right to contribute it
under that licence.
