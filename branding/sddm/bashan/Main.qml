// Bashan OS login screen.
// Deliberately plain QtQuick rather than SddmComponents: that module has
// shifted between SDDM/Qt versions, and this theme only needs a password
// box, a session picker and a power menu.
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.bgColour

    property string accent: config.accentColour
    property string dim:    config.dimColour
    property string fg:     config.textColour

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // Keeps the form readable whatever the wallpaper is doing behind it.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 1.0; color: "#99000000" }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 26

        Image {
            source: config.logo
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 150
            Layout.preferredHeight: 150
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Text {
            text: "Bashan OS"
            color: root.fg
            font.pointSize: 20
            font.family: config.fontFamily
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 420
            Layout.preferredHeight: 196
            radius: 18
            color: config.panelColour
            opacity: 0.92
            border.color: config.borderColour
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                ComboBox {
                    id: userBox
                    Layout.fillWidth: true
                    model: userModel
                    textRole: "name"
                    currentIndex: userModel.lastIndex
                }

                TextField {
                    id: password
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "Password"
                    focus: true
                    color: root.fg
                    onAccepted: loginButton.doLogin()
                    background: Rectangle {
                        radius: 10
                        color: config.bgColour
                        border.width: 1
                        border.color: password.activeFocus ? root.accent
                                                           : config.borderColour
                    }
                }

                Button {
                    id: loginButton
                    Layout.fillWidth: true
                    text: "Log in"
                    function doLogin() {
                        sddm.login(userBox.currentText, password.text,
                                   sessionBox.currentIndex)
                    }
                    onClicked: doLogin()
                    background: Rectangle {
                        radius: 10
                        color: parent.down ? config.accentColour : "#0e737b"
                    }
                    contentItem: Text {
                        text: loginButton.text
                        color: root.fg
                        font.family: config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Text {
            id: errorText
            text: ""
            color: "#f87171"
            font.family: config.fontFamily
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // Session picker, bottom left.
    RowLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 10
        Text {
            text: "Session"
            color: root.dim
            font.family: config.fontFamily
        }
        ComboBox {
            id: sessionBox
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
            implicitWidth: 230
        }
    }

    // Power controls, bottom right.
    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 18
        Button {
            text: "Restart"
            visible: sddm.canReboot
            onClicked: sddm.reboot()
            flat: true
            contentItem: Text { text: parent.text; color: root.dim
                                font.family: config.fontFamily }
        }
        Button {
            text: "Shut down"
            visible: sddm.canPowerOff
            onClicked: sddm.powerOff()
            flat: true
            contentItem: Text { text: parent.text; color: root.dim
                                font.family: config.fontFamily }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "That password was not accepted. Please try again."
            password.text = ""
            password.focus = true
        }
    }
}
