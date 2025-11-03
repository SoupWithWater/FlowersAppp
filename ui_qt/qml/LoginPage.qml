import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

Page {
    id: root
    signal authenticated(string role)

    background: Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#b8e6c1" }
            GradientStop { position: 1.0; color: "#6ccf90" }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24
        width: Math.min(parent.width * 0.5, 420)

        Label {
            text: qsTr("Цветочный магазин")
            font.pixelSize: 32
            font.bold: true
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 24
            color: "white"
            opacity: 0.95
            border.color: "#2e7d32"
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                TextField {
                    id: loginField
                    placeholderText: qsTr("Логин")
                    Layout.fillWidth: true
                    implicitHeight: 48
                    font.pixelSize: 18
                    placeholderTextColor: "#5f6d5f"
                    color: "#1b5e20"
                    background: Rectangle {
                        radius: 12
                        border.color: "#81c784"
                        border.width: 1.5
                        color: "#f3fbf5"
                    }
                }

                TextField {
                    id: passwordField
                    placeholderText: qsTr("Пароль")
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    implicitHeight: 52
                    font.pixelSize: 20
                    leftPadding: 18
                    rightPadding: 18
                    placeholderTextColor: "#2e7d32"
                    color: "#1b5e20"
                    font.bold: true
                    background: Rectangle {
                        radius: 16
                        border.color: "#1b5e20"
                        border.width: 2
                        color: "#ffffff"
                        layer.enabled: true
                        layer.effect: DropShadow {
                            horizontalOffset: 0
                            verticalOffset: 3
                            radius: 8
                            samples: 16
                            color: "#33000000"
                        }
                    }
                }

                Button {
                    text: qsTr("Войти")
                    Layout.fillWidth: true
                    implicitHeight: 44
                    background: Rectangle {
                        color: "#2e7d32"
                        radius: 22
                    }
                    contentItem: Label {
                        text: parent.parent.text
                        color: "white"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: backend.login(loginField.text, passwordField.text)
                }

                Label {
                    id: errorLabel
                    text: ""
                    color: "#c62828"
                    wrapMode: Text.WordWrap
                    visible: text.length > 0
                }
            }
        }
    }

    Connections {
        target: backend
        function onLoginSucceeded(user) {
            loginField.text = ""
            passwordField.text = ""
            errorLabel.text = ""
            root.authenticated(user.role)
        }
        function onLoginFailed(message) {
            errorLabel.text = message
        }
    }
}
