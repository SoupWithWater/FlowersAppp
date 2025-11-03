import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    signal logoutRequested()

    property var bouquets: []
    property var cartItems: []
    property int cartCount: 0
    property real cartTotal: 0

    header: ToolBar {
        background: Rectangle { color: "white" }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Label {
                text: qsTr("Каталог букетов")
                font.pixelSize: 24
                font.bold: true
                color: "#2e7d32"
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Корзина (%1 • %2 ₽)").arg(root.cartCount).arg(Number(root.cartTotal).toLocaleString(Qt.locale(), 'f', 0))
                background: Rectangle { color: "#2e7d32"; radius: 20 }
                contentItem: Label {
                    text: parent.parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: cartDrawer.open()
            }

            Button {
                text: qsTr("Выйти")
                background: Rectangle { color: "#a5d6a7"; radius: 20 }
                contentItem: Label {
                    text: parent.parent.text
                    color: "#2e7d32"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.logoutRequested()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        TextField {
            id: searchField
            placeholderText: qsTr("Поиск по названию")
            Layout.fillWidth: true
            onTextChanged: backend.requestCatalog(text)
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: Math.max((width - 32) / 3, 240)
            cellHeight: 220
            model: root.bouquets
            clip: true

            delegate: Rectangle {
                width: grid.cellWidth - 16
                height: grid.cellHeight - 16
                radius: 20
                color: "#d0f2d6"
                border.color: "#2e7d32"
                border.width: 1
                anchors.margins: 8

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Label { text: modelData.BouquetName; font.pixelSize: 20; font.bold: true; color: "#2e7d32" }
                    Label { text: qsTr("Упаковка: %1").arg(modelData.Pack); color: "#2e7d32" }
                    Label { text: qsTr("Стеблей: %1").arg(modelData.Count); color: "#2e7d32" }
                    Label { text: qsTr("Цена: %1 ₽").arg(modelData.Price); font.pixelSize: 18; color: "#1b5e20" }

                    Item { Layout.fillHeight: true }

                    Button {
                        text: qsTr("В корзину")
                        Layout.fillWidth: true
                        implicitHeight: 40
                        background: Rectangle { color: "#2e7d32"; radius: 18 }
                        contentItem: Label {
                            text: parent.parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: backend.cartAdd(modelData.BouquetCode, 1)
                    }
                }
            }
        }
    }

    Drawer {
        id: cartDrawer
        width: Math.min(parent.width * 0.4, 420)
        edge: Qt.RightEdge

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Label {
                text: qsTr("Корзина")
                font.pixelSize: 24
                font.bold: true
                color: "#2e7d32"
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.cartItems
                delegate: Rectangle {
                    width: parent.width
                    height: 80
                    radius: 16
                    color: "#e8f5e9"
                    border.color: "#2e7d32"
                    border.width: 1
                    anchors.margins: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: modelData.BouquetName; color: "#2e7d32"; font.bold: true }
                            Label { text: qsTr("%1 шт.").arg(modelData.Count); color: "#33691e" }
                        }

                        Label { text: qsTr("%1 ₽").arg(modelData.Total); color: "#1b5e20"; font.pixelSize: 16 }

                        Button {
                            text: "✕"
                            background: Rectangle { color: "transparent" }
                            contentItem: Label { text: parent.parent.text; color: "#c62828" }
                            onClicked: backend.cartRemove(modelData.BouquetCode)
                        }
                    }
                }
                footer: Label {
                    visible: root.cartItems.length === 0
                    text: qsTr("Корзина пуста")
                    color: "#2e7d32"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent ? parent.width : 200
                }
            }

            Label {
                text: qsTr("Итого: %1 ₽").arg(Number(root.cartTotal).toLocaleString(Qt.locale(), 'f', 0))
                font.pixelSize: 20
                font.bold: true
                color: "#1b5e20"
            }

            Button {
                text: qsTr("Оформить заказ")
                Layout.fillWidth: true
                enabled: root.cartItems.length > 0
                implicitHeight: 44
                background: Rectangle { color: "#2e7d32"; radius: 22 }
                contentItem: Label {
                    text: parent.parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    backend.placeOrder()
                    cartDrawer.close()
                }
            }
        }
    }

    Connections {
        target: backend
        function onCatalogChanged(items) {
            root.bouquets = items
        }
        function onCartChanged(items, total) {
            root.cartItems = items
            root.cartCount = items.reduce(function(acc, item) { return acc + item.Count }, 0)
            root.cartTotal = total
        }
    }

    Component.onCompleted: backend.requestCatalog("")
}
