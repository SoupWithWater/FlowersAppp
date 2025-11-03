import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent ? Math.min(parent.width * 0.6, 400) : 400
    height: visible ? implicitHeight : 0
    visible: false

    property alias text: messageLabel.text

    Rectangle {
        id: panel
        width: parent.width
        radius: 12
        color: "#2e7d32"
        opacity: 0.95
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.margins: 16

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Label {
                id: messageLabel
                text: ""
                color: "white"
                font.pixelSize: 16
                wrapMode: Text.WordWrap
            }

            Button {
                text: qsTr("Закрыть")
                Layout.alignment: Qt.AlignRight
                background: Rectangle {
                    radius: 12
                    color: "white"
                }
                contentItem: Label {
                    text: control.text
                    color: "#2e7d32"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.visible = false
            }
        }
    }

    function show(message) {
        text = message
        visible = true
    }
}
