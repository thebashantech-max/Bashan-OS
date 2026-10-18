# Keyboard layouts

## Four at a time, and why

The keyboard stack allows **four layouts at once**. Not a Plasma setting, not
a Bashan choice — `libxkbcommon` refuses more and says so:

```
Too many groups of %s for key %s (max %u); Ignoring %s defined for extra groups
```

The limit applies on Wayland too. Listing more than four does not add them,
it silently drops the extras — which is the most likely reason Arabic would
not switch on real hardware when a long list had been configured.

**Active by default:** `us`, `ara`, `es`, `fr`

**On an installed system**, whatever layout is chosen on the installer's
Keyboard page becomes active too, replacing the last default. `us` and `ara`
are never displaced: US is the fallback every machine needs if a layout
misbehaves, and Arabic is the reason this project exists.

Switch with **Alt+Shift** or **Meta+Space**. The current layout is shown in
the system tray.

## All 23, with their exact XKB names

Add any of these in **System Settings → Keyboard → Layouts**, removing one
first if four are already active.

| Language | XKB layout | Note |
|---|---|---|
| English (US) | `us` | active by default |
| Arabic | `ara` | active by default |
| Spanish | `es` | active by default |
| French | `fr` | active by default |
| German | `de` | |
| Hebrew | `il` | |
| **Syriac** | **`sy(syc)`** | needs the variant; plain `sy` is Arabic |
| **Kurdish Kurmanji** | **`tr(ku)`** | Latin, under the Turkey layout |
| **Kurdish Sorani** | **`ir(ku_ara)`** | Arabic script, under the Iran layout |
| Persian | `ir` | |
| Greek | `gr` | |
| Turkish | `tr` | |
| Portuguese | `pt` | |
| Italian | `it` | |
| Dutch | `nl` | |
| Serbian | `rs` | |
| Macedonian | `mk` | |
| Romanian | `ro` | |
| Polish | `pl` | |
| Hungarian | `hu` | |
| Bulgarian | `bg` | |
| Russian | `ru` | |
| Chinese | — | **not a layout**, see below |

Every one of these was checked against the `evdev.lst` rules file in the
image. None is missing; the three in bold need a *variant* rather than the
bare country code, and using the bare code gives the wrong script.

## Chinese

Chinese is **not a keyboard layout** and does not use one of the four slots.
It needs an input method: `ibus-libpinyin` types Chinese phonetically on top
of whichever layout is active, with `fonts-noto-cjk` for the characters.
Both ship in the image.

## System language is a separate setting

Changing the keyboard does not change the language of the menus, and
changing the language does not change the keyboard. They are set
independently, in the installer and in System Settings.
