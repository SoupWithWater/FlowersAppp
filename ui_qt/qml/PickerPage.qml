import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml

Page {
    id: root

    signal logoutRequested()

    property var activeOrders: []
    property var completedOrders: []
    property int activeIndex: -1
    property int completedIndex: -1
    property var selectedOrder: null
    property var receipt: ({})
    property bool selectionGuard: false

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

    function syncListIndexes() {
        activeList.internalChange = true
        activeList.currentIndex = activeIndex
        activeList.internalChange = false

        completedList.internalChange = true
        completedList.currentIndex = completedIndex
        completedList.internalChange = false
    }

    function applySelection(section, index) {
        if (section === "active") {
            if (index >= 0 && index < activeOrders.length) {
                activeIndex = index
                completedIndex = -1
                updateSelectedOrder(activeOrders[index])
            } else {
                activeIndex = -1
                if (tabs.currentIndex === 0)
                    updateSelectedOrder(null)
            }
        } else {
            if (index >= 0 && index < completedOrders.length) {
                completedIndex = index
                activeIndex = -1
                updateSelectedOrder(completedOrders[index])
            } else {
                completedIndex = -1
                if (tabs.currentIndex === 1)
                    updateSelectedOrder(null)
            }
        }
        syncListIndexes()
    }

    function ensureSelection(tabIndex) {
        if (selectionGuard)
            return

        selectionGuard = true

        var order = null
        if (tabIndex === 0) {
            if (activeOrders.length) {
                if (activeIndex < 0 || activeIndex >= activeOrders.length)
                    activeIndex = 0
                completedIndex = -1
                order = activeOrders[activeIndex]
            } else {
                activeIndex = -1
                completedIndex = -1
            }
        } else {
            if (completedOrders.length) {
                if (completedIndex < 0 || completedIndex >= completedOrders.length)
                    completedIndex = 0
                activeIndex = -1
                order = completedOrders[completedIndex]
            } else {
                completedIndex = -1
                activeIndex = -1
            }
        }

        syncListIndexes()
        updateSelectedOrder(order)

        selectionGuard = false
    }

    Component.onCompleted: {
        backend.requestPickerOrders()
        ensureSelection(tabs.currentIndex)
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
                onCurrentIndexChanged: ensureSelection(currentIndex)

                TabButton { text: qsTr("Активные") }
                TabButton { text: qsTr("Завершенные") }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 24
                color: "#f1f8e9"
                border.color: "#c8e6c9"
                border.width: 1

                ListView {
                    id: activeList
                    anchors.fill: parent
                    anchors.margins: 8
                    property bool internalChange: false
                    model: root.activeOrders
                    clip: true
                    spacing: 12
                    visible: tabs.currentIndex === 0
                    enabled: visible
                    currentIndex: root.activeIndex
                    highlight: Rectangle {
                        radius: 20
                        color: "#c8e6c9"
                        border.color: "#2e7d32"
                        border.width: 2
                        z: -1
                    }
                    highlightMoveDuration: 150
                    onCurrentIndexChanged: {
                        if (!internalChange)
                            applySelection("active", currentIndex)
                    }

                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        readonly property var order: modelData || ({})

                        width: (ListView.view ? ListView.view.width : ListView.width)
                        implicitHeight: activeCardContent.implicitHeight + 32
                        radius: 20
                        color: ListView.isCurrentItem ? "#e0f2f1" : "white"
                        border.color: "#a5d6a7"
                        border.width: 1

                        Column {
                            id: activeCardContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 6

                            Label {
                                text: qsTr("Заказ #%1").arg(order.OrderCode || "")
                                font.pixelSize: 18
                                font.bold: true
                                color: "#2e7d32"
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                text: qsTr("Клиент: %1 %2").arg(order.CustomerName || "").arg(order.CustomerSurname || "")
                                color: "#33691e"
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                text: qsTr("Статус: %1").arg(statusText(order.StatusCode))
                                color: "#558b2f"
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                text: qsTr("Сумма: %1").arg(formatMoney(order.TotalPrice))
                                color: "#1b5e20"
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                visible: !!order.PickerCode
                                text: qsTr("Сборщик: %1 %2").arg(order.PickerName || "").arg(order.PickerSurname || "")
                                color: "#2e7d32"
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: applySelection("active", index)
                        }
                    }
                }

                ListView {
                    id: completedList
                    anchors.fill: parent
                    anchors.margins: 8
                    property bool internalChange: false
                    model: root.completedOrders
                    clip: true
                    spacing: 12
                    visible: tabs.currentIndex === 1
                    enabled: visible
                    currentIndex: root.completedIndex
                    highlight: Rectangle {
                        radius: 20
                        color: "#ffe0b2"
                        border.color: "#fb8c00"
                        border.width: 2
                        z: -1
                    }
                    highlightMoveDuration: 150
                    onCurrentIndexChanged: {
                        if (!internalChange)
                            applySelection("completed", currentIndex)
                    }

                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        readonly property var order: modelData || ({})

                        width: (ListView.view ? ListView.view.width : ListView.width)
                        implicitHeight: completedCardContent.implicitHeight + 32
                        radius: 20
                        color: ListView.isCurrentItem ? "#fff3e0" : "white"
                        border.color: "#ffe0b2"
                        border.width: 1

                        Column {
                            id: completedCardContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 6

                            Label {
                                text: qsTr("Заказ #%1").arg(order.OrderCode || "")
                                font.pixelSize: 18
                                font.bold: true
                                color: "#ef6c00"
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                text: qsTr("Клиент: %1 %2").arg(order.CustomerName || "").arg(order.CustomerSurname || "")
                                color: "#e65100"
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                text: qsTr("Выдан: %1").arg(formatDateTime(order.ResolveTime))
                                color: "#8d6e63"
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                text: qsTr("Сумма: %1").arg(formatMoney(order.TotalPrice))
                                color: "#4e342e"
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: applySelection("completed", index)
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: tabs.currentIndex === 0 && !root.activeOrders.length
                    text: qsTr("Нет активных заказов")
                    color: "#78909c"
                }

                Label {
                    anchors.centerIn: parent
                    visible: tabs.currentIndex === 1 && !root.completedOrders.length
                    text: qsTr("Завершенных заказов пока нет")
                    color: "#78909c"
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

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Label {
                                text: qsTr("Информация о заказе")
                                font.pixelSize: 18
                                font.bold: true
                                color: "#2e7d32"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                function infoRow(title, value, color, visible) {
                                    return {
                                        title: title,
                                        value: value,
                                        color: color,
                                        visible: visible === undefined ? true : visible
                                    }
                                }

                                readonly property var rows: [
                                    infoRow(
                                        qsTr("Статус"),
                                        selectedOrder ? statusText(selectedOrder.StatusCode) : "",
                                        "#2e7d32"
                                    ),
                                    infoRow(
                                        qsTr("Сборщик"),
                                        selectedOrder && selectedOrder.PickerCode
                                            ? qsTr("%1 %2").arg(selectedOrder.PickerName || "").arg(selectedOrder.PickerSurname || "")
                                            : qsTr("Не назначен"),
                                        "#33691e"
                                    ),
                                    infoRow(
                                        qsTr("Клиент"),
                                        selectedOrder
                                            ? qsTr("%1 %2").arg(selectedOrder.CustomerName || "").arg(selectedOrder.CustomerSurname || "")
                                            : "",
                                        "#558b2f"
                                    ),
                                    infoRow(
                                        qsTr("Телефон"),
                                        selectedOrder ? selectedOrder.CustomerPhone : "",
                                        "#558b2f",
                                        selectedOrder && !!selectedOrder.CustomerPhone
                                    ),
                                    infoRow(
                                        qsTr("Создан"),
                                        selectedOrder ? formatDateTime(selectedOrder.CreationTime) : "",
                                        "#33691e"
                                    ),
                                    infoRow(
                                        qsTr("Завершен"),
                                        selectedOrder ? formatDateTime(selectedOrder.ResolveTime) : "",
                                        "#33691e",
                                        selectedOrder && !!selectedOrder.ResolveTime
                                    )
                                ]

                                Repeater {
                                    model: parent.rows

                                    delegate: RowLayout {
                                        required property var modelData
                                        visible: modelData.visible
                                        spacing: 8
                                        Layout.fillWidth: true

                                        Label {
                                            text: modelData.title
                                            font.bold: true
                                            color: modelData.color
                                            wrapMode: Text.WordWrap
                                            Layout.maximumWidth: detailColumn.width * 0.45
                                            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                                        }

                                        Label {
                                            text: modelData.value || qsTr("—")
                                            color: modelData.color
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            horizontalAlignment: Text.AlignRight
                                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: 16
                            color: "#f9fbe7"
                            border.color: "#dce775"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                Label {
                                    text: qsTr("Состав заказа")
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#827717"
                                }

                                Repeater {
                                    model: receipt.items || []

                                    delegate: RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Label {
                                            text: modelData.BouquetName
                                            Layout.fillWidth: true
                                            color: "#558b2f"
                                            wrapMode: Text.WordWrap
                                            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                                        }

                                        Label {
                                            text: qsTr("%1 × %2").arg(modelData.Count).arg(formatMoney(modelData.Price))
                                            color: "#33691e"
                                            font.family: "monospace"
                                        }

                                        Label {
                                            text: formatMoney(modelData.Count * modelData.Price)
                                            color: "#1b5e20"
                                            font.family: "monospace"
                                        }
                                    }
                                }

                                Label {
                                    visible: !(receipt.items && receipt.items.length)
                                    text: qsTr("Данные о составе заказа загружаются...")
                                    color: "#827717"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Label {
                                    text: qsTr("Итого")
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#1b5e20"
                                    font.family: "monospace"
                                }

                                Label {
                                    text: receipt.order ? formatMoney(receipt.order.TotalPrice) : formatMoney(selectedOrder.TotalPrice)
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#1b5e20"
                                    font.family: "monospace"
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Button {
                                    id: advanceButton
                                    visible: selectedOrder && selectedOrder.StatusCode < 4
                                    text: selectedOrder ? nextActionText(selectedOrder.StatusCode) : ""
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
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: advanceButton.visible ? undefined : parent.width
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
    }

    Connections {
        target: backend

        function onPickerOrdersChanged(items) {
            const previousOrder = selectedOrder
            const previousCode = previousOrder ? previousOrder.OrderCode : -1

            const actives = items.filter(function(entry) { return entry.StatusCode < 4 })
            const completed = items.filter(function(entry) { return entry.StatusCode >= 4 })

            activeOrders = actives
            completedOrders = completed

            var newSelection = null
            var nextTab = tabs.currentIndex

            if (previousCode !== -1) {
                const activeIdx = actives.findIndex(function(entry) { return entry.OrderCode === previousCode })
                if (activeIdx !== -1) {
                    activeIndex = activeIdx
                    completedIndex = -1
                    newSelection = actives[activeIdx]
                    nextTab = 0
                } else {
                    const completedIdx = completed.findIndex(function(entry) { return entry.OrderCode === previousCode })
                    if (completedIdx !== -1) {
                        completedIndex = completedIdx
                        activeIndex = -1
                        newSelection = completed[completedIdx]
                        nextTab = 1
                    }
                }
            }

            if (!newSelection) {
                if (nextTab === 0 && actives.length) {
                    activeIndex = 0
                    completedIndex = -1
                    newSelection = actives[0]
                } else if (nextTab === 1 && completed.length) {
                    completedIndex = 0
                    activeIndex = -1
                    newSelection = completed[0]
                } else if (actives.length) {
                    activeIndex = 0
                    completedIndex = -1
                    newSelection = actives[0]
                    nextTab = 0
                } else if (completed.length) {
                    completedIndex = 0
                    activeIndex = -1
                    newSelection = completed[0]
                    nextTab = 1
                } else {
                    activeIndex = -1
                    completedIndex = -1
                    newSelection = null
                    nextTab = 0
                }
            }

            if (tabs.currentIndex !== nextTab)
                tabs.currentIndex = nextTab

            if (newSelection) {
                if (nextTab === 0) {
                    activeIndex = actives.indexOf(newSelection)
                    completedIndex = -1
                } else {
                    completedIndex = completed.indexOf(newSelection)
                    activeIndex = -1
                }
            }

            ensureSelection(tabs.currentIndex)
        }

        function onReceiptReady(data) {
            receipt = data
            if (selectedOrder && data && data.order && data.order.OrderCode === selectedOrder.OrderCode) {
                selectedOrder.StatusCode = data.order.StatusCode
                selectedOrder.StatusName = data.order.StatusName
                selectedOrder.ResolveTime = data.order.ResolveTime
            }
        }
    }
}
