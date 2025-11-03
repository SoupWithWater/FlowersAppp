/* README (изменения):
1) ВО ВСЕХ Button с кастомным contentItem заменён text: control.text -> text: (parent as Button).text.
2) Убраны/переименованы дублирующиеся id: control (причина: "id is not unique").
3) TabButton уже использовали parent-паттерн — оставлено как есть.
4) Исправлена опечатка в табе: "Цеветы" -> "Цветы".
5) Ничего не трогал в логике onClicked и ваших функциях.
*/

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

            Button {
                // было id: control — убрал, чтобы id не конфликтовали
                text: qsTr("Выйти")
                background: Rectangle {
                    color: "#a5d6a7"
                    radius: 20
                }
                contentItem: Label {
                    text: (parent as Button).text
                    color: "#2e7d32"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                onClicked: root.logoutRequested()
            }

            Label {
                text: qsTr("Администрирование")
                font.pixelSize: 24
                font.bold: true
                color: "#2e7d32"
            }

            Item { Layout.fillWidth: true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TabBar {
                id: tabBar
                Layout.fillWidth: true
                currentIndex: root.indexForSection(root.currentSection)
                onCurrentIndexChanged: root.setSection(root.sectionForIndex(currentIndex))

                TabButton {
                    text: qsTr("Заказы")
                    contentItem: Label {
                        text: parent.text
                        color: (parent as TabButton).checked ? "white": "#2e7d32"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        font.bold: (parent as TabButton).checked
                    }
                    background: Rectangle{
                        implicitHeight: 40
                        radius: 18
                        color: (parent as TabButton).checked ? "#2e7d32": "#c8e6c9"
                    }
                }

                TabButton {
                    text: qsTr("Клиенты")
                    contentItem: Label {
                        text: parent.text
                        color: (parent as TabButton).checked ? "white": "#2e7d32"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        font.bold: (parent as TabButton).checked
                    }
                    background: Rectangle{
                        implicitHeight: 40
                        radius: 18
                        color: (parent as TabButton).checked ? "#2e7d32": "#c8e6c9"
                    }
                }

                TabButton {
                    text: qsTr("Сотрудники")
                    contentItem: Label {
                        text: parent.text
                        color: (parent as TabButton).checked ? "white": "#2e7d32"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        font.bold: (parent as TabButton).checked
                    }
                    background: Rectangle{
                        implicitHeight: 40
                        radius: 18
                        color: (parent as TabButton).checked ? "#2e7d32": "#c8e6c9"
                    }
                }

                TabButton {
                    text: qsTr("Букеты")
                    contentItem: Label {
                        text: parent.text
                        color: (parent as TabButton).checked ? "white": "#2e7d32"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        font.bold: (parent as TabButton).checked
                    }
                    background: Rectangle{
                        implicitHeight: 40
                        radius: 18
                        color: (parent as TabButton).checked ? "#2e7d32": "#c8e6c9"
                    }
                }

                TabButton {
                    text: qsTr("Цветы")   // исправлено
                    contentItem: Label {
                        text: parent.text
                        color: (parent as TabButton).checked ? "white": "#2e7d32"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        font.bold: (parent as TabButton).checked
                    }
                    background: Rectangle{
                        implicitHeight: 40
                        radius: 18
                        color: (parent as TabButton).checked ? "#2e7d32": "#c8e6c9"
                    }
                }
            }

            Button {
                id: addButton
                text: "+"
                Layout.preferredWidth: 48
                Layout.preferredHeight: 40
                background: Rectangle {
                    color: "#2e7d32"
                    radius: 20
                }
                contentItem: Label {
                    text: (parent as Button).text
                    color: "white"
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.openRecord(root.emptyRecord(root.currentSection), true)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 20
            color: "#f1f8f2"
            border.color: "#c8e6c9"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Label {
                    text: root.sectionTitle(root.currentSection)
                    font.pixelSize: 22
                    font.bold: true
                    color: "#2e7d32"
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12
                    clip: true
                    model: root.recordsForSection(root.currentSection)
                    ScrollBar.vertical: ScrollBar { }

                    delegate: Rectangle {
                        width: listView.width
                        implicitHeight: Math.max(88, contentColumn.implicitHeight + 24)
                        radius: 16
                        color: "white"
                        border.color: root.isCurrentRecord(modelData) ? "#2e7d32" : "#c8e6c9"
                        border.width: root.isCurrentRecord(modelData) ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            ColumnLayout {
                                id: contentColumn
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: root.summaryForRecord(root.currentSection, modelData)
                                    color: "#2e7d32"
                                    font.pixelSize: 18
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    text: root.detailForRecord(root.currentSection, modelData)
                                    visible: text.length > 0
                                    color: "#4e6e4e"
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Button {
                                // было id: control — убрал
                                text: "✏️"
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 40
                                background: Rectangle {
                                    color: "#a5d6a7"
                                    radius: 18
                                }
                                contentItem: Label {
                                    text: (parent as Button).text
                                    color: "#1b5e20"
                                    font.pixelSize: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: root.openRecord(modelData, false)
                            }
                        }
                    }

                    footer: Label {
                        visible: listView.count === 0
                        text: qsTr("Список пуст")
                        color: "#2e7d32"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        width: listView.width
                    }
                }
            }
        }
    }

    Dialog {
        id: editDialog
        modal: true
        property bool creating: false
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        width: Math.min(root.width * 0.6, 520)
        height: Math.min(root.height * 0.8, 520)
        title: (creating ? qsTr("Новая запись: %1") : qsTr("Редактирование: %1")).arg(sectionTitle(root.currentSection))
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: root.clearSelection()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical: ScrollBar { }

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: root.formFields(root.currentSection)
                        delegate: ColumnLayout {
                            spacing: 4
                            Label { text: modelData.label; color: "#2e7d32" }
                            TextField {
                                text: root.currentRecord && root.currentRecord[modelData.key] !== undefined ? String(root.currentRecord[modelData.key]) : ""
                                placeholderText: modelData.placeholder
                                readOnly: modelData.readOnly === true
                                onTextChanged: root.updateField(modelData.key, text)
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    text: qsTr("Удалить")
                    visible: !editDialog.creating
                    Layout.preferredWidth: 120
                    background: Rectangle { color: "#c62828"; radius: 18 }
                    contentItem: Label {
                        text: (parent as Button).text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.deleteCurrent()
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Отмена")
                    Layout.preferredWidth: 120
                    background: Rectangle { color: "#a5d6a7"; radius: 18 }
                    contentItem: Label {
                        text: (parent as Button).text
                        color: "#2e7d32"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: editDialog.close()
                }

                Button {
                    text: qsTr("Сохранить")
                    Layout.preferredWidth: 140
                    background: Rectangle { color: "#2e7d32"; radius: 18 }
                    contentItem: Label {
                        text: (parent as Button).text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.saveCurrent()
                }
            }
        }
    }

    // --- функции без изменений ---
    function setSection(section) {
        if (currentSection === section)
            return
        currentSection = section
        backend.requestAdminData(section)
        clearSelection()
        if (editDialog.visible)
            editDialog.close()
    }

    function sectionForIndex(index) {
        switch (index) {
        case 0: return "orders"
        case 1: return "customers"
        case 2: return "employees"
        case 3: return "bouquets"
        case 4: return "flowers"
        default: return "orders"
        }
    }

    function indexForSection(section) {
        switch (section) {
        case "customers": return 1
        case "employees": return 2
        case "bouquets": return 3
        case "flowers": return 4
        default: return 0
        }
    }

    function recordsForSection(section) { return dataStore[section] || [] }
    function loadRecord(record) { currentRecord = record ? JSON.parse(JSON.stringify(record)) : ({}) }
    function openRecord(record, creating) { loadRecord(record); editDialog.creating = creating; editDialog.open() }
    function emptyRecord(section) {
        var fields = formFields(section)
        var result = ({})
        for (var i = 0; i < fields.length; ++i) {
            var field = fields[i]
            result[field.key] = field.defaultValue !== undefined ? field.defaultValue : ""
        }
        return result
    }
    function clearSelection() { currentRecord = ({}); editDialog.creating = false }
    function isCurrentRecord(record) {
        var key = primaryKey(currentSection)
        return currentRecord && record && currentRecord[key] !== undefined && currentRecord[key] == record[key]
    }
    function updateField(key, value) { var u = Object.assign({}, currentRecord || ({})); u[key] = value; currentRecord = u }
    function saveCurrent() { if (!currentRecord) return; backend.saveAdminRecord(currentSection, currentRecord); editDialog.close() }
    function deleteCurrent() {
        var key = primaryKey(currentSection)
        if (!currentRecord || !currentRecord[key]) return
        backend.deleteAdminRecord(currentSection, currentRecord[key])
        editDialog.close()
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
                { key: "PhoneNumber", label: qsTr("Телефон"), placeholder: "" },
                { key: "Login", label: qsTr("Логин"), placeholder: "" },
                { key: "Password", label: qsTr("Пароль"), placeholder: "" },
                { key: "Name", label: qsTr("Имя"), placeholder: "" },
                { key: "Surname", label: qsTr("Фамилия"), placeholder: "" }
            ]
        case "employees":
            return [
                { key: "EmployeeCode", label: qsTr("Код"), placeholder: "" },
                { key: "Login", label: qsTr("Логин"), placeholder: "" },
                { key: "Password", label: qsTr("Пароль"), placeholder: "" },
                { key: "Name", label: qsTr("Имя"), placeholder: "" },
                { key: "Surname", label: qsTr("Фамилия"), placeholder: "" },
                { key: "PositionCode", label: qsTr("Должность (1-админ,2-сборщик)"), placeholder: "", defaultValue: 2 }
            ]
        case "bouquets":
            return [
                { key: "BouquetCode", label: qsTr("Код"), placeholder: "" },
                { key: "BouquetName", label: qsTr("Название"), placeholder: "" },
                { key: "TypeFlowerCode", label: qsTr("Код цветка"), placeholder: "" },
                { key: "Count", label: qsTr("Стеблей"), placeholder: "" },
                { key: "Pack", label: qsTr("Упаковка"), placeholder: "" },
                { key: "Price", label: qsTr("Цена"), placeholder: "" }
            ]
        case "flowers":
            return [
                { key: "TypeFlowerCode", label: qsTr("Код"), placeholder: "" },
                { key: "Name", label: qsTr("Название"), placeholder: "" },
                { key: "StockCount", label: qsTr("Остаток"), placeholder: "" }
            ]
        default:
            return [
                { key: "OrderCode", label: qsTr("Код заказа"), placeholder: "" },
                { key: "StatusCode", label: qsTr("Статус (1-4)"), placeholder: "", defaultValue: 1 },
                { key: "CreationTime", label: qsTr("Создан"), placeholder: "" },
                { key: "ResolveTime", label: qsTr("Выдан"), placeholder: "" },
                { key: "TotalPrice", label: qsTr("Сумма"), placeholder: "", defaultValue: 0 },
                { key: "PhoneNumber", label: qsTr("Телефон клиента"), placeholder: "" },
                { key: "PickerCode", label: qsTr("Код сборщика"), placeholder: "" }
            ]
        }
    }
    function summaryForRecord(section, record) {
        if (!record) return ""
        switch(section) {
        case "customers":
            var cn = [record.Surname, record.Name].filter(function(p){return p&&p.length}).join(" ")
            return cn.length ? cn : qsTr("Клиент")
        case "employees":
            var en = [record.Surname, record.Name].filter(function(p){return p&&p.length}).join(" ")
            var ec = record.EmployeeCode !== undefined ? String(record.EmployeeCode) : ""
            return en.length ? en + (ec ? " (#" + ec + ")" : "") : qsTr("Сотрудник")
        case "bouquets":
            return record.BouquetName && record.BouquetName.length ? record.BouquetName : qsTr("Букет")
        case "flowers":
            return record.Name && record.Name.length ? record.Name : qsTr("Цветок")
        default:
            var oc = record.OrderCode !== undefined ? record.OrderCode : "-"
            return qsTr("Заказ #%1").arg(oc)
        }
    }
    function detailForRecord(section, record) {
        if (!record) return ""
        switch(section) {
        case "customers":
            return qsTr("Телефон: %1 • Логин: %2")
                .arg(record.PhoneNumber || "-")
                .arg(record.Login || "-")
        case "employees":
            return qsTr("Должность: %1 • Логин: %2")
                .arg(positionName(record.PositionCode))
                .arg(record.Login || "-")
        case "bouquets":
            var price = formatCurrency(record.Price)
            return qsTr("Цена: %1 ₽ • %2 шт.")
                .arg(price)
                .arg(record.Count !== undefined ? record.Count : "-")
        case "flowers":
            return qsTr("Остаток: %1 шт.")
                .arg(record.StockCount !== undefined ? record.StockCount : "-")
        default:
            var status = record.StatusCode !== undefined ? record.StatusCode : "-"
            var total = formatCurrency(record.TotalPrice)
            var created = record.CreationTime || "-"
            return qsTr("Статус: %1 • Сумма: %2 ₽ • Создан: %3")
                .arg(status)
                .arg(total)
                .arg(created)
        }
    }
    function formatCurrency(value) {
        var n = Number(value); if (isNaN(n)) n = 0; return n.toLocaleString(Qt.locale(), 'f', 0)
    }
    function positionName(code) {
        switch(code) {
        case 1: return qsTr("Администратор")
        case 2: return qsTr("Сборщик")
        default: return qsTr("Сотрудник")
        }
    }

    Connections {
        target: backend
        function onAdminDataChanged(section, items) {
            var updated = Object.assign({}, dataStore)
            updated[section] = items
            dataStore = updated
        }
    }

    Component.onCompleted: backend.requestAdminData(currentSection)
}