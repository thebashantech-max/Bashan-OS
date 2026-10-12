#!/usr/bin/env python3
"""Generate the Bashan Plasma theme artefacts from theme/palette.json.

Everything here is derived from the palette, so changing a colour there
changes the colour scheme, the dock and the login screen together.

Produces:
  theme/color-schemes/Bashan.colors              Plasma colour scheme
  theme/look-and-feel/com.bashan.desktop/        look-and-feel package,
                                                 including the dock layout
  theme/icons/Bashan-{A,B}/index.theme           icon theme indexes

Every plasmoid id written into the layout was read out of the actual Debian
packages (plasma-desktop-data, plasma-workspace-data, plasma-widgets-addons),
not guessed.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PAL = json.loads((ROOT / "theme/palette.json").read_text())
ICON_SIZES = (16, 22, 24, 32, 48, 64, 128, 256)

# Dock, left to right. The Kickoff launcher is an applet, not a pinned task,
# so it is not in this list.
PINNED = [
    "applications:brave-browser.desktop",
    "applications:google-chrome.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:bashan-app.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.kamoso.desktop",
]


def rgb(token: str) -> str:
    h = PAL[token].lstrip("#")[:6]
    return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))


def colour_scheme() -> str:
    common = f"""BackgroundNormal={rgb('bg_base')}
BackgroundAlternate={rgb('bg_raised')}
ForegroundNormal={rgb('text')}
ForegroundInactive={rgb('text_dim')}
ForegroundActive={rgb('accent')}
ForegroundLink={rgb('accent')}
ForegroundVisited={rgb('accent_dim')}
ForegroundNegative={rgb('error')}
ForegroundNeutral={rgb('warn')}
ForegroundPositive={rgb('ok')}
DecorationFocus={rgb('accent')}
DecorationHover={rgb('accent_dim')}"""
    sections = [
        ("Colors:Window", "bg_base"), ("Colors:View", "bg_deep"),
        ("Colors:Button", "bg_raised"), ("Colors:Selection", "accent_deep"),
        ("Colors:Tooltip", "bg_surface"), ("Colors:Complementary", "bg_void"),
        ("Colors:Header", "bg_raised"),
    ]
    out = ["[General]", "ColorScheme=Bashan", "Name=Bashan",
           f"shadeSortColumn=true", "",
           "[WM]", f"activeBackground={rgb('bg_raised')}",
           f"activeForeground={rgb('text')}",
           f"inactiveBackground={rgb('bg_base')}",
           f"inactiveForeground={rgb('text_faint')}",
           f"frame={rgb('accent_deep')}", f"inactiveFrame={rgb('border')}", ""]
    for name, bg in sections:
        body = common.replace(f"BackgroundNormal={rgb('bg_base')}",
                              f"BackgroundNormal={rgb(bg)}")
        if name == "Colors:Selection":
            body = body.replace(f"ForegroundNormal={rgb('text')}",
                                f"ForegroundNormal={rgb('text')}")
        out += [f"[{name}]", body, ""]
    return "\n".join(out)


def layout_js() -> str:
    return '''// Bashan OS - desktop and dock layout.
// Applied by the "Bashan" look-and-feel. Every plasmoid id below was read
// from the Debian packages that ship them, not guessed.

var wallpaper = "/usr/share/wallpapers/Bashan/contents/images/3840x2160.png";

var desks = desktops();
for (var i = 0; i < desks.length; i++) {
    var d = desks[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file://" + wallpaper);
    d.writeConfig("FillMode", 2);          // scaled, keep aspect, crop
}

// ---- the dock -----------------------------------------------------------
// A floating pill: centred, only as wide as its contents, clear of the
// screen edge. Plasma 6 draws the blur and the 1 px border itself once
// floating is on.
var dock = new Panel;
dock.location = "bottom";
dock.alignment = "center";
dock.height = 60;
dock.floating = true;
dock.lengthMode = "fit";
dock.hiding = "none";

// Left-most: the Bashan logo launcher.
var launcher = dock.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "bashan-launcher");
launcher.writeConfig("primaryActions", 0);

// Pinned apps, in the agreed order.
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", "LAUNCHERS");
tasks.writeConfig("groupingStrategy", 0);       // never group
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("indicateAudioStreams", true);

// Right end: the indicators a laptop cannot do without - battery, wi-fi,
// volume, bluetooth - plus a compact clock.
dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.systemtray");
var clock = dock.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", false);
clock.writeConfig("fontWeight", 500);

// ---- desktop widgets ----------------------------------------------------
var desk = desks[0];
if (desk) {
    var mon = desk.addWidget("org.kde.plasma.systemmonitor");
    mon.geometry = Qt.rect(60, 60, 420, 260);

    var weather = desk.addWidget("org.kde.plasma.weather");
    weather.geometry = Qt.rect(60, 350, 420, 220);

    var notes = desk.addWidget("org.kde.plasma.notes");
    notes.geometry = Qt.rect(60, 600, 420, 300);
}
'''.replace("LAUNCHERS", ",".join(PINNED))


def main() -> None:
    cs = ROOT / "theme/color-schemes"
    cs.mkdir(parents=True, exist_ok=True)
    (cs / "Bashan.colors").write_text(colour_scheme())
    print(f"   theme/color-schemes/Bashan.colors")

    laf = ROOT / "theme/look-and-feel/com.bashan.desktop"
    (laf / "contents/layouts").mkdir(parents=True, exist_ok=True)
    (laf / "metadata.json").write_text(json.dumps({
        "KPlugin": {
            "Id": "com.bashan.desktop",
            "Name": "Bashan",
            "Description": "The Bashan OS desktop look and feel",
            "Authors": [{"Name": "Bashan Tech LLC"}],
            "License": "Proprietary",
            "Version": "1.0",
            "Website": "https://bashan.app",
        },
        "KPackageStructure": "Plasma/LookAndFeel",
    }, indent=4) + "\n")
    (laf / "contents/defaults").write_text(f"""[kdeglobals][General]
ColorScheme=Bashan
AccentColor={PAL['accent']}

[kdeglobals][Icons]
Theme=Bashan

[kdeglobals][KDE]
widgetStyle=Breeze

[plasmarc][Theme]
name=breeze-dark

[kcminputrc][Mouse]
cursorTheme=breeze_cursors

[Wallpaper][org.kde.image][General]
Image=/usr/share/wallpapers/Bashan/contents/images/3840x2160.png

[kscreenlockerrc][Greeter][Wallpaper][org.kde.image][General]
Image=/usr/share/wallpapers/Bashan/contents/images/bashan-ridge-login-1920x1080.png
""")
    (laf / "contents/layouts/org.kde.plasma.desktop-layout.js").write_text(layout_js())
    print(f"   theme/look-and-feel/com.bashan.desktop/ (metadata, defaults, layout)")

    for variant in ("A", "B"):
        d = ROOT / f"theme/icons/Bashan-{variant}"
        d.mkdir(parents=True, exist_ok=True)
        dirs = ",".join(f"{s}x{s}/places" for s in ICON_SIZES)
        body = [f"""[Icon Theme]
Name=Bashan
Comment=Bashan OS icons (trash variant {variant})
Inherits=breeze-dark,breeze,hicolor
Directories={dirs}
"""]
        for s in ICON_SIZES:
            body.append(f"[{s}x{s}/places]\nSize={s}\nContext=Places\nType=Fixed\n")
        (d / "index.theme").write_text("\n".join(body))
    print("   theme/icons/Bashan-{A,B}/index.theme")


if __name__ == "__main__":
    main()
