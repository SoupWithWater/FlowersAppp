import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

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

    Item {
        anchors.fill: parent

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24
            width: Math.min(parent.width * 0.5, 420)

            Label {
                width: parent.width
                text: qsTr("Цветочный магазин")
                font.pixelSize: 32
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                id: formCard
                width: parent.width
                implicitHeight: formColumn.implicitHeight + 48
                radius: 24
                color: "white"
                opacity: 0.95
                border.color: "#2e7d32"
                border.width: 2

                Column {
                    id: formColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 24
                    spacing: 16

                    TextField {
                        id: loginField
                        width: parent.width
                        placeholderText: qsTr("Логин")
                        implicitHeight: 48
                        font.pixelSize: 18
                        leftPadding: 18
                        rightPadding: 18
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
                        width: parent.width
                        placeholderText: qsTr("Пароль")
                        echoMode: TextInput.Password
                        implicitHeight: 48
                        font.pixelSize: 18
                        leftPadding: 18
                        rightPadding: 18
                        placeholderTextColor: "#5f6d5f"
                        color: "#1b5e20"
                        background: Rectangle {
                            radius: 12
                            border.color: "#81c784"
                            border.width: 1.5
                            color: "#f3fbf5"
                        }
                    }

                    Button {
                        id: loginButton
                        width: parent.width
                        text: qsTr("Войти")
                        implicitHeight: 44
                        background: Rectangle {
                            color: "#2e7d32"
                            radius: 22
                        }
                        contentItem: Label {
                            text: control.text
                            color: "white"
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: backend.login(loginField.text, passwordField.text)
                    }

                    Label {
                        id: errorLabel
                        width: parent.width
                        text: ""
                        color: "#c62828"
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        visible: text.length > 0
                    }
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
