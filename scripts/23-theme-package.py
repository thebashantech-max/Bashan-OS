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

from _palette import ROOT, VARIANTS, rgb_csv

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


def colour_scheme(v) -> str:
    PAL = v.pal

    def rgb(token: str) -> str:
        return rgb_csv(PAL[token])

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
    out = ["[General]", f"ColorScheme={v.scheme}", f"Name={v.scheme}",
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


def layout_js(v) -> str:
    return '''// Bashan OS - desktop and dock layout.
// Applied by the "Bashan" look-and-feel. Every plasmoid id below was read
// from the Debian packages that ship them, not guessed.

var wallpaper = "WALLPAPER";

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
// The system monitor, weather and notes live in the DOCK, not on the
// desktop. Desktop applet placement is not controllable: Folder View has
// no position system at all, and on the Desktop containment Plasma
// arranges applets itself and ignores assigned geometry. Both were proven
// in QEMU. A panel positions its own contents reliably, so that is where
// they go.
var mon = dock.addWidget("org.kde.plasma.systemmonitor");
var weather = dock.addWidget("org.kde.plasma.weather");
var notes = dock.addWidget("org.kde.plasma.notes");

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.systemtray");
var clock = dock.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", false);
clock.writeConfig("fontWeight", 500);

// ---- the desktop itself --------------------------------------------------
// No widgets are placed on the desktop. The only desktop item is the Trash,
// and it is a real trash:/ link in ~/Desktop (shipped via /etc/skel), drawn
// by Folder View - which is what makes its icon switch between the empty
// and full states by itself. Folder View also mirrors under right-to-left
// languages, so the Trash moves to the opposite corner on its own.
'''.replace("LAUNCHERS", ",".join(PINNED)) \
     .replace("WALLPAPER",
              f"/usr/share/wallpapers/Bashan/contents/images/"
              f"bashan-ridge{v.suffix}-3840x2160.png")


def look_and_feel(v) -> None:
    """One look-and-feel package per variant.

    Shipping two of them is what gives the user a one-click switch with no
    code of ours involved: System Settings > Colours and System Settings >
    Global Theme list both, and applying one sets the scheme, the desktop
    theme and both wallpapers together.
    """
    laf = ROOT / "theme/look-and-feel" / v.lookandfeel
    (laf / "contents/layouts").mkdir(parents=True, exist_ok=True)
    (laf / "metadata.json").write_text(json.dumps({
        "KPlugin": {
            "Id": v.lookandfeel,
            "Name": "Bashan" if not v.is_light else "Bashan Light",
            "Description": ("The Bashan OS desktop look and feel"
                            if not v.is_light else
                            "The Bashan OS desktop look and feel, light"),
            "Authors": [{"Name": "Bashan Tech LLC"}],
            "License": "Proprietary",
            "Version": "1.0",
            "Website": "https://bashan.app",
        },
        "KPackageStructure": "Plasma/LookAndFeel",
    }, indent=4) + "\n")

    wall = f"/usr/share/wallpapers/Bashan/contents/images/bashan-ridge{v.suffix}"
    # plasmarc Theme: deliberately Breeze, not our own "Bashan" desktop theme.
    # Plasma 6 draws a floating panel's pill, blur and border itself, so the
    # Breeze theme already gives the dock the right shape; the dark variant
    # was verified that way in Stage 9. Our generated desktop themes exist
    # (see scripts/25-desktop-theme.py) but selecting one is an untested
    # change, so it is not made here. Switching both lines together is all
    # it would take.
    (laf / "contents/defaults").write_text(f"""[kdeglobals][General]
ColorScheme={v.scheme}
AccentColor={v.pal['accent']}

[kdeglobals][Icons]
Theme=Bashan

[kdeglobals][KDE]
widgetStyle=Breeze

[plasmarc][Theme]
name={'breeze-light' if v.is_light else 'breeze-dark'}

[kcminputrc][Mouse]
cursorTheme=breeze_cursors

[Wallpaper][org.kde.image][General]
Image={wall}-3840x2160.png

[kscreenlockerrc][Greeter][Wallpaper][org.kde.image][General]
Image={wall}-login-1920x1080.png
""")
    (laf / "contents/layouts/org.kde.plasma.desktop-layout.js").write_text(layout_js(v))
    print(f"   theme/look-and-feel/{v.lookandfeel}/ (metadata, defaults, layout)")


def main() -> None:
    cs = ROOT / "theme/color-schemes"
    cs.mkdir(parents=True, exist_ok=True)
    for v in VARIANTS.values():
        (cs / f"{v.scheme}.colors").write_text(colour_scheme(v))
        print(f"   theme/color-schemes/{v.scheme}.colors")
        look_and_feel(v)

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

    # Index for the light icon theme. 10-lb-config.sh builds Bashan-Light by
    # copying the installed Bashan theme, dropping this index over it and
    # laying the light launcher on top. The inherit chain is the whole point:
    # Bashan inherits breeze-dark, whose icons are tinted pale for dark
    # backgrounds and nearly vanish on a light one, so the light theme
    # inherits plain breeze instead.
    li = ROOT / "theme/icons/_light"
    li.mkdir(parents=True, exist_ok=True)
    dirs = ",".join(f"{s}x{s}/places" for s in ICON_SIZES)
    dirs += "," + ",".join(f"{s}x{s}/apps" for s in ICON_SIZES)
    body = [f"""[Icon Theme]
Name=Bashan Light
Comment=Bashan OS icons, light
Inherits=breeze,hicolor
Directories={dirs}
"""]
    for s in ICON_SIZES:
        body.append(f"[{s}x{s}/places]\nSize={s}\nContext=Places\nType=Fixed\n")
    for s in ICON_SIZES:
        body.append(f"[{s}x{s}/apps]\nSize={s}\nContext=Applications\nType=Fixed\n")
    (li / "index.theme").write_text("\n".join(body))
    print("   theme/icons/_light/index.theme")


if __name__ == "__main__":
    main()
