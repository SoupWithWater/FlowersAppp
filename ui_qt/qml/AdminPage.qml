import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root
    signal logoutRequested()

    property string currentSection: "orders"
    property var dataStore: ({})
    property var currentRecord: ({})

    header: ToolBar {
        background: Rectangle { color: "white" }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Label {
                text: qsTr("Администрирование")
                font.pixelSize: 24
                font.bold: true
                color: "#2e7d32"
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Выйти")
                background: Rectangle { color: "#a5d6a7"; radius: 20 }
                contentItem: Label { text: parent.parent.text; color: "#2e7d32"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: root.logoutRequested()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            currentIndex: 0
            TabButton { text: qsTr("Заказы"); onClicked: root.setSection("orders") }
            TabButton { text: qsTr("Клиенты"); onClicked: root.setSection("customers") }
            TabButton { text: qsTr("Сотрудники"); onClicked: root.setSection("employees") }
            TabButton { text: qsTr("Букеты"); onClicked: root.setSection("bouquets") }
            TabButton { text: qsTr("Цветы"); onClicked: root.setSection("flowers") }
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            handle: Rectangle { implicitWidth: 6; color: "#c8e6c9" }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                clip: true
                model: root.recordsForSection(root.currentSection)

                delegate: Rectangle {
                    width: listView.width
                    height: implicitHeight
                    radius: 16
                    color: root.isCurrentRecord(modelData) ? "#a5d6a7" : "#d0f2d6"
                    border.color: "#2e7d32"
                    border.width: 1
                    anchors.margins: 4

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4
                        property var recordData: modelData

                        Repeater {
                            model: Object.keys(recordData)
                            delegate: Label {
                                required property string modelData
                                text: recordData[modelData] === null ? modelData + ": -" : modelData + ": " + recordData[modelData]
                                color: "#2e7d32"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.loadRecord(modelData)
                    }
                }
            }

            ScrollView {
                Layout.preferredWidth: Math.min(parent.width * 0.4, 420)

                ColumnLayout {
                    id: form
                    width: parent.width
                    spacing: 12
                    padding: 12

                    Label {
                        text: root.sectionTitle(root.currentSection)
                        font.pixelSize: 22
                        font.bold: true
                        color: "#2e7d32"
                    }

                    Repeater {
                        model: root.formFields(root.currentSection)
                        delegate: ColumnLayout {
                            spacing: 4
                            Label { text: modelData.label; color: "#2e7d32" }
                            TextField {
                                text: root.currentRecord[modelData.key] ? String(root.currentRecord[modelData.key]) : ""
                                placeholderText: modelData.placeholder
                                enabled: !modelData.readOnly
                                onEditingFinished: root.updateField(modelData.key, text)
                            }
                        }
                    }

                    RowLayout {
                        spacing: 12
                        Button {
                            text: qsTr("Назад")
                            Layout.fillWidth: true
                            background: Rectangle { color: "#a5d6a7"; radius: 18 }
                            contentItem: Label { text: parent.parent.text; color: "#2e7d32"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: root.clearSelection()
                        }
                        Button {
                            text: qsTr("Сохранить")
                            Layout.fillWidth: true
                            background: Rectangle { color: "#2e7d32"; radius: 18 }
                            contentItem: Label { text: parent.parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: root.saveCurrent()
                        }
                    }

                    Button {
                        text: qsTr("Удалить")
                        Layout.fillWidth: true
                        background: Rectangle { color: "#c62828"; radius: 18 }
                        contentItem: Label { text: parent.parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: root.deleteCurrent()
                    }
                }
            }
        }
    }

    function setSection(section) {
        currentSection = section
        listView.model = root.recordsForSection(section)
        backend.requestAdminData(section)
        clearSelection()
    }

    function recordsForSection(section) {
        return dataStore[section] || []
    }

    function loadRecord(record) {
        currentRecord = JSON.parse(JSON.stringify(record))
    }

    function clearSelection() {
        currentRecord = ({})
    }

    function isCurrentRecord(record) {
        var key = primaryKey(currentSection)
        return currentRecord && record && currentRecord[key] === record[key]
    }

    function updateField(key, value) {
        if (!currentRecord)
            currentRecord = ({})
        currentRecord[key] = value
    }

    function saveCurrent() {
        backend.saveAdminRecord(currentSection, currentRecord)
    }

    function deleteCurrent() {
        var key = primaryKey(currentSection)
        if (!currentRecord || !currentRecord[key])
            return
        backend.deleteAdminRecord(currentSection, currentRecord[key])
        clearSelection()
    }

    function primaryKey(section) {
        switch(section) {
        case "customers": return "PhoneNumber"
        case "employees": return "EmployeeCode"
        case "bouquets": return "BouquetCode"
        case "flowers": return "TypeFlowerCode"
        default: return "OrderCode"
        }
    }

    function sectionTitle(section) {
        switch(section) {
        case "customers": return qsTr("Клиенты")
        case "employees": return qsTr("Сотрудники")
        case "bouquets": return qsTr("Букеты")
        case "flowers": return qsTr("Цветы")
        default: return qsTr("Заказы")
        }
    }

    function formFields(section) {
        switch(section) {
        case "customers":
            return [
                { key: "PhoneNumber", label: qsTr("Телефон"), placeholder: "+79..." },
                { key: "Login", label: qsTr("Логин"), placeholder: "client01" },
                { key: "Password", label: qsTr("Пароль"), placeholder: "пароль" },
                { key: "Name", label: qsTr("Имя"), placeholder: "Имя" },
                { key: "Surname", label: qsTr("Фамилия"), placeholder: "Фамилия" }
            ]
        case "employees":
            return [
                { key: "EmployeeCode", label: qsTr("Код"), placeholder: "" },
                { key: "Login", label: qsTr("Логин"), placeholder: "picker" },
                { key: "Password", label: qsTr("Пароль"), placeholder: "пароль" },
                { key: "Name", label: qsTr("Имя"), placeholder: "Имя" },
                { key: "Surname", label: qsTr("Фамилия"), placeholder: "Фамилия" },
                { key: "PositionCode", label: qsTr("Должность (1-админ,2-сборщик)"), placeholder: "2" }
            ]
        case "bouquets":
            return [
                { key: "BouquetCode", label: qsTr("Код"), placeholder: "" },
                { key: "BouquetName", label: qsTr("Название"), placeholder: "Новый букет" },
                { key: "TypeFlowerCode", label: qsTr("Код цветка"), placeholder: "1" },
                { key: "Count", label: qsTr("Стеблей"), placeholder: "5" },
                { key: "Pack", label: qsTr("Упаковка"), placeholder: "Крафт" },
                { key: "Price", label: qsTr("Цена"), placeholder: "1500" }
            ]
        case "flowers":
            return [
                { key: "TypeFlowerCode", label: qsTr("Код"), placeholder: "" },
                { key: "Name", label: qsTr("Название"), placeholder: "Роза" },
                { key: "StockCount", label: qsTr("Остаток"), placeholder: "100" }
            ]
        default:
            return [
                { key: "OrderCode", label: qsTr("Код заказа"), placeholder: "" },
                { key: "StatusCode", label: qsTr("Статус (1-4)"), placeholder: "1" },
                { key: "CreationTime", label: qsTr("Создан"), placeholder: "2025-01-01T10:00:00" },
                { key: "ResolveTime", label: qsTr("Выдан"), placeholder: "2025-01-01T12:00:00" },
                { key: "TotalPrice", label: qsTr("Сумма"), placeholder: "1500" },
                { key: "PhoneNumber", label: qsTr("Телефон клиента"), placeholder: "+7900..." },
                { key: "PickerCode", label: qsTr("Код сборщика"), placeholder: "2" }
            ]
        }
    }

    Connections {
        target: backend
        function onAdminDataChanged(section, items) {
            var updated = Object.assign({}, dataStore)
            updated[section] = items
            dataStore = updated
            if (section === currentSection) {
                listView.model = root.recordsForSection(section)
            }
        }
    }

    Component.onCompleted: backend.requestAdminData(currentSection)
}
