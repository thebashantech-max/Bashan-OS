// Bashan OS — "Get to Know Bashan OS".
//
// Run by /usr/bin/bashan-welcome through the `qml` runner from qml-qt6.
// Every QML module used here (QtQuick, Controls, Layouts, QtCore,
// QtMultimedia) was already in the image for Calamares and Plasma, so the
// whole application costs 0.1 MB.
//
// Deliberately large type throughout: this is the first thing a new user
// sees, and it has to be readable by someone who does not love computers.
// Lets the inline components below refer to the window's id. qmllint asks
// for this explicitly; without it the references work but are deprecated.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import QtMultimedia

ApplicationWindow {
    id: win
    visible: true
    width: 1000; height: 720
    minimumWidth: 820; minimumHeight: 600
    title: tr("w.p1.title")
    color: pal.bg_base

    // ---- state ----------------------------------------------------------
    readonly property string home: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "")
    property var cat: ({ languages: {}, strings: {} })
    property var pal: ({ bg_base: "#0b1018", bg_raised: "#121a28", bg_deep: "#070b12",
                         text: "#e6f0fa", text_dim: "#8aa0bd", text_faint: "#5a6e8c",
                         accent: "#22d3ee", border: "#2a3a52", mint: "#5eead4" })
    property string lang: "en"
    property bool rtl: false
    property int page: 0
    readonly property int lastPage: 5

    Settings {
        id: cfg
        location: "file://" + win.home + "/.config/bashan-welcome.conf"
        property bool showAtStartup: false
    }

    function tr(key) {
        if (cat.strings[lang] && cat.strings[lang][key]) return cat.strings[lang][key]
        if (cat.strings["en"] && cat.strings["en"][key]) return cat.strings["en"][key]
        return key
    }

    // Read a local JSON file. XMLHttpRequest on file:// is permitted in QML
    // and avoids needing any C++ or Python helper just to load data.
    function readJson(path, cb) {
        var x = new XMLHttpRequest()
        x.onreadystatechange = function() {
            if (x.readyState === XMLHttpRequest.DONE && x.responseText) {
                try { cb(JSON.parse(x.responseText)) } catch (e) { }
            }
        }
        x.open("GET", "file://" + path); x.send()
    }

    function readText(path, cb) {
        var x = new XMLHttpRequest()
        x.onreadystatechange = function() {
            if (x.readyState === XMLHttpRequest.DONE) cb(x.responseText || "")
        }
        x.open("GET", "file://" + path); x.send()
    }

    // QML cannot start a process. Actions that must run a command go out
    // through a URL scheme that /usr/bin/bashan-action handles, registered
    // by bashan-action.desktop. Opening documents and the software centre
    // needs no helper: file:// and appstream: are handled by the system.
    function act(what) { Qt.openUrlExternally("bashan-action:" + what) }

    Component.onCompleted: {
        readJson("/usr/share/bashan/welcome/i18n.json", function(d) {
            cat = d
            var n = Qt.locale().name.split("_")[0]
            lang = d.strings.hasOwnProperty(n) ? n : "en"
            rtl = d.languages[lang] ? d.languages[lang].rtl : false
        })
        // The theme the toggle last applied; absent on a fresh system.
        readText(home + "/.config/bashan-theme", function(t) {
            var light = t.trim() === "light"
            readJson(light ? "/usr/share/bashan/welcome/palette-light.json"
                           : "/usr/share/bashan/welcome/palette.json",
                     function(p) { pal = p })
        })
        // Starts the welcome music. If the song was left out by the rights
        // guard the player reports invalid media and this does nothing.
        music.play()
    }

    LayoutMirroring.enabled: rtl
    LayoutMirroring.childrenInherit: true

    // QtQuick Controls draw themselves from the window palette. Without
    // this they use the Basic style's defaults, which put near-black
    // checkbox labels on our dark background and give every button a white
    // face. Setting it once here is inherited by every control below.
    palette.window: pal.bg_base
    palette.windowText: pal.text
    palette.base: pal.bg_deep
    palette.text: pal.text
    palette.button: pal.bg_raised
    palette.buttonText: pal.text
    palette.highlight: pal.accent
    palette.highlightedText: pal.bg_base
    palette.mid: pal.border
    palette.dark: pal.text_faint
    palette.light: pal.bg_surface
    palette.placeholderText: pal.text_faint

    // ---- the welcome music ----------------------------------------------
    // Plays once, on page 1 only, and never loops. The file is the same one
    // the boot splash uses, so it ships under the same rights guard; when
    // that guard omitted it, `source` points at nothing, `hasAudio` is false
    // and the mute button simply does not appear.
    // To swap the music, drop a WAV at /etc/bashan/welcome-song.wav. That
    // path is tried first and survives system updates, which /usr/share does
    // not. If it is absent the player reports an error and we fall back to
    // the shipped song; if that is absent too (the rights guard left it out)
    // nothing plays and the mute button does not appear.
    readonly property string songOverride: "file:///etc/bashan/welcome-song.wav"
    readonly property string songDefault: "file:///usr/share/bashan/boot-song.wav"
    MediaPlayer {
        id: music
        source: win.songOverride
        loops: 1
        audioOutput: AudioOutput { id: out; volume: 0.7 }
        onErrorOccurred: {
            if (source == win.songOverride) { source = win.songDefault; play() }
        }
    }
    property bool musicAvailable: music.mediaStatus !== MediaPlayer.NoMedia
                                  && music.mediaStatus !== MediaPlayer.InvalidMedia
    Component.onDestruction: music.stop()

    // ---- building blocks -------------------------------------------------
    component Title : Text {
        color: win.pal.text
        font.pixelSize: 40
        font.weight: Font.DemiBold
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        horizontalAlignment: win.rtl ? Text.AlignRight : Text.AlignLeft
    }
    component Body : Text {
        color: win.pal.text_dim
        font.pixelSize: 21
        lineHeight: 1.35
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        horizontalAlignment: win.rtl ? Text.AlignRight : Text.AlignLeft
    }
    component Card : Rectangle {
        default property alias content: inner.data
        color: win.pal.bg_raised
        border.color: win.pal.border
        border.width: 1
        radius: 14
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 44
        ColumnLayout {
            id: inner
            anchors { left: parent.left; right: parent.right; top: parent.top
                      margins: 18 }
            spacing: 6
        }
    }
    component CardTitle : Text {
        color: win.pal.accent
        font.pixelSize: 23
        font.weight: Font.DemiBold
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        horizontalAlignment: win.rtl ? Text.AlignRight : Text.AlignLeft
    }
    // The Basic style's checkbox indicator is drawn from palette.base with a
    // hairline border and vanishes on a dark surface. This one is visible.
    // Referenced through the control's own id rather than `parent`: inside
    // indicator/contentItem the parent is typed as a bare Item, so the
    // linter cannot check the property names.
    component BigCheck : CheckBox {
        id: ctrl
        font.pixelSize: 19
        indicator: Rectangle {
            implicitWidth: 26; implicitHeight: 26
            x: ctrl.LayoutMirroring.enabled ? ctrl.width - width - 4 : 4
            y: ctrl.height / 2 - height / 2
            radius: 5
            color: ctrl.checked ? win.pal.accent : win.pal.bg_deep
            border.color: ctrl.checked ? win.pal.accent : win.pal.text_faint
            border.width: 2
            Text {
                anchors.centerIn: parent
                visible: ctrl.checked
                text: "\u2713"
                color: win.pal.bg_base
                font.pixelSize: 18; font.bold: true
            }
        }
        contentItem: Text {
            text: ctrl.text
            font: ctrl.font
            color: win.pal.text
            verticalAlignment: Text.AlignVCenter
            leftPadding: ctrl.LayoutMirroring.enabled ? 0 : 36
            rightPadding: ctrl.LayoutMirroring.enabled ? 36 : 0
        }
    }
    component BigButton : Button {
        font.pixelSize: 19
        implicitHeight: 48
        padding: 16
    }

    // ---- pages ------------------------------------------------------------
    StackLayout {
        id: stack
        currentIndex: win.page
        anchors { fill: parent; margins: 0 }

        // 1 - logo and greeting
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 120, 760)
                spacing: 18
                Image {
                    source: "file:///usr/share/icons/hicolor/256x256/apps/bashan-launcher.png"
                    sourceSize.width: 220; sourceSize.height: 220
                    Layout.alignment: Qt.AlignHCenter
                    fillMode: Image.PreserveAspectFit
                }
                Text {
                    text: win.tr("w.p1.title")
                    color: win.pal.text; font.pixelSize: 46; font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
                Text {
                    text: win.tr("w.p1.sub")
                    color: win.pal.accent; font.pixelSize: 22
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: win.tr("w.p1.greeting")
                    color: win.pal.text_dim; font.pixelSize: 22
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
                BigButton {
                    visible: win.musicAvailable
                    Layout.alignment: Qt.AlignHCenter
                    text: out.muted ? win.tr("w.unmute") : win.tr("w.mute")
                    onClicked: out.muted = !out.muted
                }
            }
        }

        // 2 - what Bashan OS is
        ScrollView {
            clip: true
            ColumnLayout {
                width: stack.width - 120
                x: 60; y: 56
                spacing: 20
                Title { text: win.tr("w.p2.title") }
                Body  { text: win.tr("w.p2.body") }
            }
        }

        // 3 - the tour
        ScrollView {
            clip: true
            ColumnLayout {
                width: stack.width - 120
                x: 60; y: 44
                spacing: 14
                Title { text: win.tr("w.p3.title") }
                Repeater {
                    model: ["w.p3.dock", "w.p3.launcher", "w.p3.widgets",
                            "w.p3.trash", "w.p3.apps"]
                    Card {
                        id: tourCard
                        // Required under "pragma ComponentBehavior: Bound":
                        // without it modelData does not resolve in a delegate.
                        required property var modelData
                        CardTitle { text: win.tr(tourCard.modelData + ".h") }
                        Body { text: win.tr(tourCard.modelData + ".b"); font.pixelSize: 19 }
                    }
                }
            }
        }

        // 4 - language, theme, startup sound
        ScrollView {
            clip: true
            ColumnLayout {
                width: stack.width - 120
                x: 60; y: 30
                spacing: 10
                Title { text: win.tr("w.p4.title") }
                Card {
                    CardTitle { text: win.tr("w.p4.lang.h") }
                    Body { text: win.tr("w.p4.lang.b"); font.pixelSize: 19 }
                    Text {
                        // Double negation: a missing entry yields undefined,
                        // which Qt refuses to assign to a bool property.
                        visible: !!(win.cat.languages[win.lang]
                                    && !win.cat.languages[win.lang].reviewed
                                    && win.lang !== "en")
                        text: "⚠  " + (win.cat.languages[win.lang]
                              ? win.cat.languages[win.lang].native + ": "
                                + win.cat.languages[win.lang].confidence : "")
                              + " — not yet checked by a native speaker"
                        color: win.pal.text_faint; font.pixelSize: 15
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }
                }
                Card {
                    CardTitle { text: win.tr("w.p4.theme.h") }
                    Body { text: win.tr("w.p4.theme.b"); font.pixelSize: 19 }
                    BigButton {
                        text: win.tr("w.p4.theme.btn")
                        Layout.topMargin: 8
                        onClicked: win.act("theme-toggle")
                    }
                }
                Card {
                    CardTitle { text: win.tr("w.p4.song.h") }
                    Body { text: win.tr("w.p4.song.b"); font.pixelSize: 19 }
                    BigCheck {
                        id: songBox
                        Layout.topMargin: 8
                        text: win.tr("w.p4.song.toggle")
                        checked: true
                        // Writing /etc/bashan/boot-sound.conf needs root, so
                        // this goes through pkexec in the action handler.
                        onToggled: win.act("boot-sound-" + (checked ? "on" : "off"))
                    }
                }
            }
        }

        // 5 - more software
        ScrollView {
            clip: true
            ColumnLayout {
                width: stack.width - 120
                x: 60; y: 44
                spacing: 14
                Title { text: win.tr("w.p5.title") }
                Card {
                    CardTitle { text: win.tr("w.p5.chrome.h") }
                    Body { text: win.tr("w.p5.chrome.b"); font.pixelSize: 19 }
                    BigButton {
                        text: win.tr("w.p5.chrome.h")
                        Layout.topMargin: 8
                        onClicked: win.act("install-chrome")
                    }
                }
                Card {
                    CardTitle { text: win.tr("w.p5.discover.h") }
                    Body { text: win.tr("w.p5.discover.b"); font.pixelSize: 19 }
                    BigButton {
                        text: win.tr("w.p5.discover.btn")
                        Layout.topMargin: 8
                        // Discover registers the appstream: scheme itself.
                        onClicked: Qt.openUrlExternally("appstream:")
                    }
                }
            }
        }

        // 6 - privacy and legal
        ScrollView {
            clip: true
            ColumnLayout {
                width: stack.width - 120
                x: 60; y: 44
                spacing: 14
                Title { text: win.tr("w.p6.title") }
                Body  { text: win.tr("w.p6.body") }
                Text {
                    text: "⚠  " + win.tr("w.p6.draft")
                    color: win.pal.text_faint; font.pixelSize: 17
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                    horizontalAlignment: win.rtl ? Text.AlignRight : Text.AlignLeft
                }
                RowLayout {
                    spacing: 12
                    Layout.topMargin: 8
                    Repeater {
                        model: [
                          { f: "NOTICE.md",  k: "Third-party licences" },
                          { f: "TERMS.md",   k: "Terms of use" },
                          { f: "PRIVACY.md", k: "Privacy statement" }
                        ]
                        BigButton {
                            id: legalBtn
                            required property var modelData
                            text: legalBtn.modelData.k
                            onClicked: Qt.openUrlExternally(
                                "file:///usr/share/doc/bashan/legal/" + legalBtn.modelData.f)
                        }
                    }
                }
                Body {
                    text: win.tr("w.reopen"); font.pixelSize: 17
                    Layout.topMargin: 10
                }
            }
        }
    }

    // ---- footer -----------------------------------------------------------
    footer: Rectangle {
        height: 92
        color: win.pal.bg_deep
        Rectangle { width: parent.width; height: 1; color: win.pal.border }

        RowLayout {
            anchors { fill: parent; leftMargin: 28; rightMargin: 28 }
            spacing: 16

            BigCheck {
                id: startupBox
                text: win.tr("w.showatstart")
                checked: cfg.showAtStartup
                onToggled: cfg.showAtStartup = checked
            }

            Item { Layout.fillWidth: true }

            Text {
                text: (win.page + 1) + " / " + (win.lastPage + 1)
                color: win.pal.text_faint; font.pixelSize: 17
            }
            BigButton {
                text: win.tr("w.nav.back")
                enabled: win.page > 0
                onClicked: win.page--
            }
            BigButton {
                text: win.page === win.lastPage ? win.tr("w.nav.done") : win.tr("w.nav.next")
                highlighted: true
                onClicked: win.page === win.lastPage ? win.close() : win.page++
            }
        }
    }

    // The music belongs to page 1 only: leaving it stops it for good, and
    // coming back does not start it again.
    onPageChanged: if (win.page !== 0) music.stop()
}
