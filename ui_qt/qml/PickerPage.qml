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
                    text: (parent as Button).text
                    color: "#2e7d32"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
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
            currentIndex: -1
            highlight: Rectangle {
                radius: 20
                color: "#b9e4bf"
                border.color: "#2e7d32"
                border.width: 1
            }
            highlightFollowsCurrentItem: true
            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < root.orders.length) {
                    const order = root.orders[currentIndex]
                    backend.requestReceipt(order.OrderCode)
                } else {
                    root.receipt = ({})
                }
            }

            delegate: Rectangle {
                required property int index
                width: parent.width
                height: 160
                radius: 20
                color: orderList.currentIndex === index ? "transparent" : "#d0f2d6"
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
                    Label {
                        visible: !!modelData.PickerCode
                        text: qsTr("Сборщик: %1 %2").arg(modelData.PickerName || "").arg(modelData.PickerSurname || "")
                        color: "#2e7d32"
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        text: modelData.StatusCode === 1 ? qsTr("Начать сборку") : modelData.StatusCode === 2 ? qsTr("Собран") : qsTr("Выдан")
                        Layout.fillWidth: true
                        enabled: modelData.StatusCode < 4
                        implicitHeight: 40
                        background: Rectangle { color: "#2e7d32"; radius: 18 }
                        contentItem: Label {
                            text: (parent as Button).text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 16
                            font.bold: true
                        }
                        onClicked: backend.advanceOrderStatus(modelData.OrderCode)
                    }
                }

                TapHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchScreen
                    onTapped: orderList.currentIndex = index
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
                        Label { text: receipt.order ? qsTr("Статус: %1").arg(receipt.order.StatusName) : ""; color: "#2e7d32" }
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
                                text: (parent as Button).text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 16
                                font.bold: true
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
            const oldIndex = orderList.currentIndex
            const previousOrder = oldIndex >= 0 && oldIndex < root.orders.length
                    ? root.orders[orderList.currentIndex]
                    : null
            root.orders = items
            if (!items.length) {
                orderList.currentIndex = -1
                root.receipt = ({})
                return
            }
            var newIndex = -1
            if (previousOrder) {
                newIndex = items.findIndex(function(entry) { return entry.OrderCode === previousOrder.OrderCode })
            }
            if (newIndex < 0) {
                newIndex = 0
            }
            orderList.currentIndex = newIndex
            if (newIndex === oldIndex && newIndex >= 0 && newIndex < root.orders.length) {
                backend.requestReceipt(root.orders[newIndex].OrderCode)
            }
        }
        function onReceiptReady(data) {
            root.receipt = data
        }
    }

    Component.onCompleted: backend.requestPickerOrders()
}
