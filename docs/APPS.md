# Bashan OS — Preinstalled Applications

Lean by intent. Installed size and idle RAM are measured and recorded per group
as each group lands (Stage 4).

## Groups

**Office** — LibreOffice Writer, Calc, Impress, Draw, Base, Math, with Qt
integration and dictionaries.

**Internet** — Brave (baked in from Brave's official apt repo). Thunderbird for
mail, calendar and contacts — no Evolution, no Kontact. Google Chrome: its apt
repo and signing key are preconfigured, but the `.deb` is **not** baked into the
ISO; the user installs it on first boot or through Discover. The dock keeps its
Chrome slot.

**Bashan app** — a Brave app-mode wrapper: a `.desktop` launching
`--app=https://bashan.app`, owner's logo as icon, its own WM class. No Electron,
no Tauri. The app zip, its source and any keys never enter git or the ISO.

**Viewers / editors** — Okular, Gwenview, Spectacle, Kate, Ark, calculator,
camera app.

**System** — System Settings, Discover with Flatpak/Flathub, KInfoCenter, System
Monitor, KDE Partition Manager, Filelight, CUPS printing setup, Bluetooth setup,
firewall GUI, a snapshot/backup tool, a drivers helper.

**Bashan welcome app** — language, theme, boot-song toggle.

## Open

- Telegram: owner decides at the app stage (Stage 4).

## Measurements

| Group | Installed size | Idle RAM |
|---|---|---|
| _pending Stage 4_ | | |
