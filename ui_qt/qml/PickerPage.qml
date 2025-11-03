import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root

    signal logoutRequested()

    property var activeOrders: []
    property var completedOrders: []
    property int activeCurrentIndex: -1
    property int completedCurrentIndex: -1
    property var selectedOrder: null
    property var receipt: ({})
    property int tabWatcher: tabs ? tabs.currentIndex : 0

    onTabWatcherChanged: ensureSelectionForTab(tabWatcher)
    Component.onCompleted: ensureSelectionForTab(tabs.currentIndex)

    function statusText(statusCode) {
        switch (statusCode) {
        case 1:
            return qsTr("Оформлен")
        case 2:
            return qsTr("Сборка")
        case 3:
            return qsTr("Готов")
        case 4:
            return qsTr("Выдан")
        default:
            return qsTr("Неизвестно")
        }
    }

    function nextActionText(statusCode) {
        switch (statusCode) {
        case 1:
            return qsTr("Начать сборку")
        case 2:
            return qsTr("Заказ собран")
        case 3:
            return qsTr("Выдать заказ")
        default:
            return ""
        }
    }

    function formatMoney(amount) {
        if (amount === undefined || amount === null)
            return ""
        const numeric = Number(amount)
        if (isNaN(numeric))
            return amount
        return numeric.toLocaleString(Qt.locale("ru_RU"), "f", numeric % 1 === 0 ? 0 : 2) + " ₽"
    }

    function formatDateTime(value) {
        if (!value)
            return "—"
        return value.toString().replace("T", " ")
    }

    function updateSelectedOrder(order) {
        if (order) {
            const previousCode = selectedOrder ? selectedOrder.OrderCode : -1
            selectedOrder = order
            if (order.OrderCode !== previousCode) {
                receipt = ({})
            }
            backend.requestReceipt(order.OrderCode)
        } else {
            selectedOrder = null
            receipt = ({})
        }
    }

    function updateListSelections() {
        activeList.internalChange = true
        activeList.currentIndex = activeCurrentIndex
        activeList.internalChange = false

        completedList.internalChange = true
        completedList.currentIndex = completedCurrentIndex
        completedList.internalChange = false
    }

    function selectFromList(section, index) {
        if (section === "active") {
            activeCurrentIndex = index
            completedCurrentIndex = -1
            updateSelectedOrder(index >= 0 && index < activeOrders.length ? activeOrders[index] : null)
        } else {
            completedCurrentIndex = index
            activeCurrentIndex = -1
            updateSelectedOrder(index >= 0 && index < completedOrders.length ? completedOrders[index] : null)
        }
        updateListSelections()
    }

    function ensureSelectionForTab(tabIndex) {
        if (tabIndex === 0) {
            if (activeOrders.length) {
                const index = activeCurrentIndex >= 0 ? activeCurrentIndex : 0
                activeCurrentIndex = index
                completedCurrentIndex = -1
                updateSelectedOrder(activeOrders[index])
            } else {
                activeCurrentIndex = -1
                updateSelectedOrder(null)
            }
        } else {
            if (completedOrders.length) {
                const index = completedCurrentIndex >= 0 ? completedCurrentIndex : 0
                completedCurrentIndex = index
                activeCurrentIndex = -1
                updateSelectedOrder(completedOrders[index])
            } else {
                completedCurrentIndex = -1
                updateSelectedOrder(null)
            }
        }
        updateListSelections()
    }

    function statusText(statusCode) {
        switch (statusCode) {
        case 1:
            return qsTr("Оформлен")
        case 2:
            return qsTr("Сборка")
        case 3:
            return qsTr("Готов")
        case 4:
            return qsTr("Выдан")
        default:
            return qsTr("Неизвестно")
        }
    }

    function nextActionText(statusCode) {
        switch (statusCode) {
        case 1:
            return qsTr("Начать сборку")
        case 2:
            return qsTr("Заказ собран")
        case 3:
            return qsTr("Выдать заказ")
        default:
            return ""
        }
    }

    function formatMoney(amount) {
        if (amount === undefined || amount === null)
            return ""
        const numeric = Number(amount)
        if (isNaN(numeric))
            return amount
        return numeric.toLocaleString(Qt.locale("ru_RU"), "f", numeric % 1 === 0 ? 0 : 2) + " ₽"
    }

    function formatDateTime(value) {
        if (!value)
            return "—"
        return value.toString().replace("T", " ")
    }

    function updateSelectedOrder(order) {
        if (order) {
            const previousCode = selectedOrder ? selectedOrder.OrderCode : -1
            selectedOrder = order
            if (order.OrderCode !== previousCode) {
                receipt = ({})
            }
            backend.requestReceipt(order.OrderCode)
        } else {
            selectedOrder = null
            receipt = ({})
        }
    }

    function updateListSelections() {
        activeList.internalChange = true
        activeList.currentIndex = activeCurrentIndex
        activeList.internalChange = false

        completedList.internalChange = true
        completedList.currentIndex = completedCurrentIndex
        completedList.internalChange = false
    }

    function selectFromList(section, index) {
        if (section === "active") {
            activeCurrentIndex = index
            completedCurrentIndex = -1
            updateSelectedOrder(index >= 0 && index < activeOrders.length ? activeOrders[index] : null)
        } else {
            completedCurrentIndex = index
            activeCurrentIndex = -1
            updateSelectedOrder(index >= 0 && index < completedOrders.length ? completedOrders[index] : null)
        }
        updateListSelections()
    }

    function ensureSelectionForTab(tabIndex) {
        if (tabIndex === 0) {
            if (activeOrders.length) {
                const index = activeCurrentIndex >= 0 ? activeCurrentIndex : 0
                activeCurrentIndex = index
                completedCurrentIndex = -1
                updateSelectedOrder(activeOrders[index])
            } else {
                activeCurrentIndex = -1
                updateSelectedOrder(null)
            }
        } else {
            if (completedOrders.length) {
                const index = completedCurrentIndex >= 0 ? completedCurrentIndex : 0
                completedCurrentIndex = index
                activeCurrentIndex = -1
                updateSelectedOrder(completedOrders[index])
            } else {
                completedCurrentIndex = -1
                updateSelectedOrder(null)
            }
        }
        updateListSelections()
    }

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

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 24

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            TabBar {
                id: tabs
                Layout.fillWidth: true
                currentIndex: 0

                TabButton {
                    text: qsTr("Активные")
                }

                TabButton {
                    text: qsTr("Завершенные")
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 24
                color: "#f1f8e9"
                border.color: "#c8e6c9"
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

            TabBar {
                id: tabs
                Layout.fillWidth: true
                currentIndex: 0

                TabButton {
                    text: qsTr("Активные")
                }

                TabButton {
                    text: qsTr("Завершенные")
                }

                onCurrentIndexChanged: ensureSelectionForTab(currentIndex)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 24
                color: "#f1f8e9"
                border.color: "#c8e6c9"
                border.width: 1

                StackLayout {
                    id: listStack
                    anchors.fill: parent
                    anchors.margins: 8
                    currentIndex: tabs.currentIndex

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: activeList
                            anchors.fill: parent
                            property bool internalChange: false
                            model: root.activeOrders
                            clip: true
                            spacing: 12
                            currentIndex: root.activeCurrentIndex
                            focus: true
                            highlight: Rectangle {
                                radius: 20
                                color: "#c8e6c9"
                                border.color: "#2e7d32"
                                border.width: 2
                            }
                            highlightMoveDuration: 150
                            onCurrentIndexChanged: {
                                if (!internalChange) {
                                    root.selectFromList("active", currentIndex)
                                }
                            }

                            delegate: Rectangle {
                                required property int index
                                width: ListView.view.width
                                height: 120
                                radius: 20
                                color: ListView.isCurrentItem ? "#e0f2f1" : "white"
                                border.color: "#a5d6a7"
                                border.width: 1
                                opacity: modelData ? 1 : 0

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 6

                                    Label {
                                        text: qsTr("Заказ #%1").arg(modelData.OrderCode)
                                        font.pixelSize: 18
                                        font.bold: true
                                        color: "#2e7d32"
                                    }

                                    Label {
                                        text: qsTr("Клиент: %1 %2").arg(modelData.CustomerName).arg(modelData.CustomerSurname)
                                        color: "#33691e"
                                    }

                                    Label {
                                        text: qsTr("Статус: %1").arg(root.statusText(modelData.StatusCode))
                                        color: "#558b2f"
                                    }

                                    Label {
                                        text: qsTr("Сумма: %1").arg(root.formatMoney(modelData.TotalPrice))
                                        color: "#1b5e20"
                                    }

                                    Label {
                                        visible: !!modelData.PickerCode
                                        text: qsTr("Сборщик: %1 %2").arg(modelData.PickerName || "").arg(modelData.PickerSurname || "")
                                        color: "#2e7d32"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.selectFromList("active", index)
                                }
                            }
                        }

                        Label {
                            visible: !root.activeOrders.length
                            anchors.centerIn: parent
                            text: qsTr("Нет активных заказов")
                            color: "#78909c"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: completedList
                            anchors.fill: parent
                            property bool internalChange: false
                            model: root.completedOrders
                            clip: true
                            spacing: 12
                            currentIndex: root.completedCurrentIndex
                            highlight: Rectangle {
                                radius: 20
                                color: "#ffe0b2"
                                border.color: "#fb8c00"
                                border.width: 2
                            }
                            highlightMoveDuration: 150
                            onCurrentIndexChanged: {
                                if (!internalChange) {
                                    root.selectFromList("completed", currentIndex)
                                }
                            }

                            delegate: Rectangle {
                                required property int index
                                width: ListView.view.width
                                height: 120
                                radius: 20
                                color: ListView.isCurrentItem ? "#fff3e0" : "white"
                                border.color: "#ffe0b2"
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 6

                                    Label {
                                        text: qsTr("Заказ #%1").arg(modelData.OrderCode)
                                        font.pixelSize: 18
                                        font.bold: true
                                        color: "#ef6c00"
                                    }

                                    Label {
                                        text: qsTr("Клиент: %1 %2").arg(modelData.CustomerName).arg(modelData.CustomerSurname)
                                        color: "#e65100"
                                    }

                                    Label {
                                        text: qsTr("Выдан: %1").arg(root.formatDateTime(modelData.ResolveTime))
                                        color: "#8d6e63"
                                    }

                                    Label {
                                        text: qsTr("Сумма: %1").arg(root.formatMoney(modelData.TotalPrice))
                                        color: "#4e342e"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.selectFromList("completed", index)
                                }
                            }
                        }

                        Label {
                            visible: !root.completedOrders.length
                            anchors.centerIn: parent
                            text: qsTr("Завершенных заказов пока нет")
                            color: "#78909c"
                        }
                    }
                }

                TapHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchScreen
                    onTapped: orderList.currentIndex = index
                }
            }
        }

        ScrollView {
            Layout.preferredWidth: Math.min(parent.width * 0.45, 420)
            Layout.fillHeight: true
            contentWidth: detailColumn.implicitWidth
            contentHeight: detailColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: detailColumn
                width: parent.width
                spacing: 16

                Label {
                    text: selectedOrder ? qsTr("Заказ #%1").arg(selectedOrder.OrderCode) : qsTr("Выберите заказ")
                    font.pixelSize: 24
                    font.bold: true
                    color: "#2e7d32"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: !!selectedOrder
                    Layout.fillWidth: true
                    radius: 24
                    color: "white"
                    border.color: "#c8e6c9"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: qsTr("Статус: %1").arg(root.statusText(selectedOrder.StatusCode))
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#2e7d32"
                                }

                                Label {
                                    text: selectedOrder && selectedOrder.PickerCode
                                          ? qsTr("Сборщик: %1 %2").arg(selectedOrder.PickerName || "").arg(selectedOrder.PickerSurname || "")
                                          : qsTr("Сборщик не назначен")
                                    color: "#33691e"
                                }

                                Label {
                                    text: qsTr("Клиент: %1 %2").arg(selectedOrder.CustomerName).arg(selectedOrder.CustomerSurname)
                                    color: "#558b2f"
                                }

                                Label {
                                    text: selectedOrder && selectedOrder.CustomerPhone
                                          ? qsTr("Телефон: %1").arg(selectedOrder.CustomerPhone)
                                          : ""
                                    color: "#558b2f"
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#e0e0e0" }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: qsTr("Создан: %1").arg(root.formatDateTime(selectedOrder.CreationTime))
                                color: "#607d8b"
                            }

                            Label {
                                text: selectedOrder && selectedOrder.ResolveTime
                                      ? qsTr("Выдан: %1").arg(root.formatDateTime(selectedOrder.ResolveTime))
                                      : qsTr("Выдан: —")
                                color: "#607d8b"
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#e0e0e0" }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: qsTr("Состав заказа")
                                font.pixelSize: 18
                                font.bold: true
                                color: "#2e7d32"
                            }

                            Repeater {
                                model: receipt.items || []

                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Label {
                                        text: modelData.BouquetName
                                        Layout.fillWidth: true
                                        color: "#2e7d32"
                                        font.family: "monospace"
                                    }

                                    Label {
                                        text: qsTr("%1 × %2").arg(modelData.Count).arg(root.formatMoney(modelData.Price))
                                        color: "#33691e"
                                        font.family: "monospace"
                                    }

                                    Label {
                                        text: root.formatMoney(modelData.Count * modelData.Price)
                                        color: "#1b5e20"
                                        font.bold: true
                                        font.family: "monospace"
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#e0e0e0" }

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    text: qsTr("Итого")
                                    Layout.fillWidth: true
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#1b5e20"
                                    font.family: "monospace"
                                }

                                Label {
                                    text: receipt.order ? root.formatMoney(receipt.order.TotalPrice) : root.formatMoney(selectedOrder.TotalPrice)
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#1b5e20"
                                    font.family: "monospace"
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Button {
                                visible: selectedOrder && selectedOrder.StatusCode < 4
                                text: selectedOrder ? root.nextActionText(selectedOrder.StatusCode) : ""
                                Layout.fillWidth: true
                                enabled: selectedOrder && selectedOrder.StatusCode < 4
                                implicitHeight: 44
                                background: Rectangle { color: "#2e7d32"; radius: 22 }
                                contentItem: Label {
                                    text: (parent as Button).text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                                onClicked: backend.advanceOrderStatus(selectedOrder.OrderCode)
                            }

                            Button {
                                visible: selectedOrder && receipt.order && receipt.order.StatusCode >= 4
                                text: qsTr("Распечатать чек")
                                Layout.fillWidth: selectedOrder && selectedOrder.StatusCode < 4 ? false : true
                                Layout.preferredWidth: selectedOrder && selectedOrder.StatusCode < 4 ? undefined : parent.width
                                implicitHeight: 44
                                background: Rectangle { color: "#1b5e20"; radius: 22 }
                                contentItem: Label {
                                    text: (parent as Button).text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                                onClicked: backend.notification(qsTr("Чек отправлен на печать"))
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: backend

        function onPickerOrdersChanged(items) {
            const previousOrder = root.selectedOrder
            const previousCode = previousOrder ? previousOrder.OrderCode : -1

            const actives = items.filter(function(entry) { return entry.StatusCode < 4 })
            const completed = items.filter(function(entry) { return entry.StatusCode >= 4 })

            root.activeOrders = actives
            root.completedOrders = completed

            var newSelection = null
            if (previousCode !== -1) {
                newSelection = actives.find(function(entry) { return entry.OrderCode === previousCode })
                if (!newSelection) {
                    newSelection = completed.find(function(entry) { return entry.OrderCode === previousCode })
                }
            }

            var newActiveIndex = -1
            var newCompletedIndex = -1

            if (newSelection) {
                newActiveIndex = actives.findIndex(function(entry) { return entry.OrderCode === newSelection.OrderCode })
                newCompletedIndex = completed.findIndex(function(entry) { return entry.OrderCode === newSelection.OrderCode })
            } else {
                if (tabs.currentIndex === 0 && actives.length) {
                    newSelection = actives[0]
                    newActiveIndex = 0
                } else if (tabs.currentIndex === 1 && completed.length) {
                    newSelection = completed[0]
                    newCompletedIndex = 0
                } else if (actives.length) {
                    tabs.currentIndex = 0
                    newSelection = actives[0]
                    newActiveIndex = 0
                } else if (completed.length) {
                    tabs.currentIndex = 1
                    newSelection = completed[0]
                    newCompletedIndex = 0
                }
            }

            root.activeCurrentIndex = newActiveIndex
            root.completedCurrentIndex = newCompletedIndex
            root.updateListSelections()
            root.updateSelectedOrder(newSelection)
        }

        function onReceiptReady(data) {
            root.receipt = data
            if (root.selectedOrder && data && data.order && data.order.OrderCode === root.selectedOrder.OrderCode) {
                root.selectedOrder.StatusCode = data.order.StatusCode
                root.selectedOrder.StatusName = data.order.StatusName
                root.selectedOrder.ResolveTime = data.order.ResolveTime
            }
        }
    }

}

