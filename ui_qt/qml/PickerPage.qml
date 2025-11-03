import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    signal logoutRequested()

    property var orders: []
    property var receipt: ({})

    header: ToolBar {
        background: Rectangle { color: "white" }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Button {
                text: qsTr("Выйти")
                background: Rectangle { color: "#a5d6a7"; radius: 20 }
                contentItem: Label {
                    text: control.text
                    color: "#2e7d32"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Layout.preferredWidth: implicitWidth
                Layout.alignment: Qt.AlignVCenter
                onClicked: root.logoutRequested()
            }

            Label {
                text: qsTr("Сбор заказов")
                font.pixelSize: 24
                font.bold: true
                color: "#2e7d32"
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }
    }

    SplitView {
        anchors.fill: parent
        anchors.margins: 16
        orientation: Qt.Horizontal
        handle: Rectangle { implicitWidth: 6; color: "#c8e6c9" }

        ListView {
            id: orderList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.orders
            clip: true
            spacing: 12

            delegate: Rectangle {
                width: parent.width
                height: 150
                radius: 20
                color: "#d0f2d6"
                border.color: "#2e7d32"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Label { text: qsTr("Заказ #%1").arg(modelData.OrderCode); font.pixelSize: 20; font.bold: true; color: "#2e7d32" }
                    Label { text: qsTr("Клиент: %1 %2").arg(modelData.CustomerName).arg(modelData.CustomerSurname); color: "#2e7d32" }
                    Label { text: qsTr("Статус: %1").arg(modelData.StatusName); color: "#33691e" }
                    Label { text: qsTr("Сумма: %1 ₽").arg(modelData.TotalPrice); color: "#1b5e20" }

                    Item { Layout.fillHeight: true }

                    Button {
                        text: modelData.StatusCode === 1 ? qsTr("Начать сборку") : modelData.StatusCode === 2 ? qsTr("Собран") : qsTr("Выдан")
                        Layout.fillWidth: true
                        enabled: modelData.StatusCode < 4
                        implicitHeight: 40
                        background: Rectangle { color: "#2e7d32"; radius: 18 }
                        contentItem: Label {
                            text: control.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: backend.advanceOrderStatus(modelData.OrderCode)
                    }
                }
            }
        }

        Flickable {
            Layout.preferredWidth: Math.min(parent.width * 0.4, 420)
            contentWidth: receiptColumn.implicitWidth
            contentHeight: receiptColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: receiptColumn
                width: parent.width
                spacing: 12

                Label {
                    text: qsTr("Чек")
                    font.pixelSize: 24
                    font.bold: true
                    color: "#2e7d32"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 16
                    border.color: "#2e7d32"
                    border.width: 1
                    color: "white"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        Label { text: qsTr("Магазин цветов 'Флора'"); color: "#1b5e20"; font.bold: true }
                        Label { text: receipt.order ? qsTr("Заказ #%1").arg(receipt.order.OrderCode) : ""; color: "#2e7d32" }
                        Label { text: receipt.order ? qsTr("Создан: %1").arg(receipt.order.CreationTime) : ""; color: "#33691e" }
                        Label { text: receipt.order && receipt.order.ResolveTime ? qsTr("Выдан: %1").arg(receipt.order.ResolveTime) : ""; color: "#33691e" }

                        Repeater {
                            model: receipt.items || []
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Label { text: modelData.BouquetName; Layout.fillWidth: true; color: "#2e7d32" }
                                Label { text: qsTr("%1 × %2").arg(modelData.Count).arg(modelData.Price); color: "#2e7d32" }
                                Label { text: qsTr("%1 ₽").arg(modelData.Count * modelData.Price); color: "#1b5e20" }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#c8e6c9" }

                        Label { text: receipt.order ? qsTr("Итого: %1 ₽").arg(receipt.order.TotalPrice) : ""; font.pixelSize: 20; font.bold: true; color: "#1b5e20" }
                        Button {
                            text: qsTr("Распечатать")
                            Layout.fillWidth: true
                            enabled: receipt.order && receipt.order.ResolveTime
                            background: Rectangle { color: "#2e7d32"; radius: 18 }
                            contentItem: Label {
                                text: control.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: backend.notification("Чек отправлен на печать")
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: backend
        function onPickerOrdersChanged(items) {
            root.orders = items
        }
        function onReceiptReady(data) {
            root.receipt = data
        }
    }

    Component.onCompleted: backend.requestPickerOrders()
}
