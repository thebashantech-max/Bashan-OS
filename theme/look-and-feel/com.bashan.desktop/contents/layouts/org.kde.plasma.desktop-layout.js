// Bashan OS - desktop and dock layout.
// Applied by the "Bashan" look-and-feel. Every plasmoid id below was read
// from the Debian packages that ship them, not guessed.

var wallpaper = "/usr/share/wallpapers/Bashan/contents/images/bashan-ridge-3840x2160.png";

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
tasks.writeConfig("launchers", "applications:brave-browser.desktop,applications:google-chrome.desktop,applications:org.kde.dolphin.desktop,applications:bashan-app.desktop,applications:org.kde.konsole.desktop,applications:org.kde.kamoso.desktop");
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

    // Trash, bottom-right: correct for the eight left-to-right languages.
    // For Arabic, Hebrew, Syriac, Sorani and Persian it is moved to the
    // bottom-left at login by /usr/libexec/bashan/bashan-desktop-locale,
    // which also handles the user changing language later.
    var trash = desk.addWidget("org.kde.plasma.trash");
    var sg = desk.screenGeometry;
    if (sg) {
        trash.geometry = Qt.rect(sg.width - 188, sg.height - 188, 128, 128);
    }
}
