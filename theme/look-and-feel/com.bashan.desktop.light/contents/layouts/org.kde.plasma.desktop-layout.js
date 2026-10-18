// Bashan OS - desktop and dock layout.
// Applied by the "Bashan" look-and-feel. Every plasmoid id below was read
// from the Debian packages that ship them, not guessed.

// The layout writes the wallpaper straight into the desktop containment at
// first login, which OVERRIDES whatever the look-and-feel defaults say.
// Changing the defaults alone left the old ridge on screen, so this line
// is the one that actually decides what a person sees.
var wallpaper = "/usr/share/wallpapers/BashanMountain/contents/images/1920x1080.png";

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
// Say which timezone the clock is showing. In the live session that is
// UTC, which otherwise just looks like the wrong time to someone whose
// machine is set up correctly.
clock.writeConfig("showLocalTimezone", true);
clock.writeConfig("fontWeight", 500);

// ---- the desktop itself --------------------------------------------------
// No widgets are placed on the desktop. The only desktop item is the Trash,
// and it is a real trash:/ link in ~/Desktop (shipped via /etc/skel), drawn
// by Folder View - which is what makes its icon switch between the empty
// and full states by itself. Folder View also mirrors under right-to-left
// languages, so the Trash moves to the opposite corner on its own.
