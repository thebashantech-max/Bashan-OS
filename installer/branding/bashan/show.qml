/* Bashan OS installer slideshow.
 * Shown while files are copied, so it has to hold attention for several
 * minutes without saying anything that needs understanding.
 */
import QtQuick 2.5
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 9000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Image {
            id: bg1
            source: "slide-bg.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
        }
        Column {
            anchors.centerIn: parent
            spacing: 18
            width: parent.width * 0.8
            Text {
                text: qsTr("Welcome to Bashan OS")
                color: "#e6f0fa"
                font.pixelSize: 40
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: qsTr("Your computer is being set up. This usually takes about ten minutes. You can leave it running.")
                color: "#8aa0bd"
                font.pixelSize: 20
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }
    }

    Slide {
        Image { source: "slide-bg.png"; anchors.fill: parent; fillMode: Image.PreserveAspectCrop }
        Column {
            anchors.centerIn: parent
            spacing: 18
            width: parent.width * 0.8
            Text {
                text: qsTr("Everything you need, already installed")
                color: "#e6f0fa"
                font.pixelSize: 36
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: qsTr("Writer, spreadsheets and presentations. Email and calendar. A web browser. Photos, music and video. Nothing to download before you start.")
                color: "#8aa0bd"
                font.pixelSize: 20
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }
    }

    Slide {
        Image { source: "slide-bg.png"; anchors.fill: parent; fillMode: Image.PreserveAspectCrop }
        Column {
            anchors.centerIn: parent
            spacing: 18
            width: parent.width * 0.8
            Text {
                text: qsTr("Thirteen languages, written the right way round")
                color: "#e6f0fa"
                font.pixelSize: 36
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: qsTr("Arabic, Hebrew, Syriac, Sorani and Persian read right to left, and Bashan OS lays itself out to match. You can change language at any time.")
                color: "#8aa0bd"
                font.pixelSize: 20
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }
    }

    Slide {
        Image { source: "slide-bg.png"; anchors.fill: parent; fillMode: Image.PreserveAspectCrop }
        Column {
            anchors.centerIn: parent
            spacing: 18
            width: parent.width * 0.8
            Text {
                text: qsTr("Private by default")
                color: "#e6f0fa"
                font.pixelSize: 36
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: qsTr("Bashan OS collects nothing and reports nothing. No usage data, no accounts, no tracking. Published by Bashan Tech LLC.")
                color: "#8aa0bd"
                font.pixelSize: 20
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }
    }

    function onActivate()   { advanceTimer.running = true;  }
    function onLeave()      { advanceTimer.running = false; }
}
