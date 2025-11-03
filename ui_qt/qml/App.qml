import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    visible: true
    color: "#E9F7EF"
    title: qsTr("Цветочный магазин")

    property string currentRole: ""

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: loginPage
    }

    Component {
        id: loginPage
        LoginPage {
            onAuthenticated: function(role) {
                window.currentRole = role
                if (role === "client") {
                    stack.replace(clientPage)
                } else if (role === "picker") {
                    stack.replace(pickerPage)
                } else if (role === "admin") {
                    stack.replace(adminPage)
                }
            }
        }
    }

    Component { id: clientPage; ClientPage { onLogoutRequested: stack.replace(loginPage) } }
    Component { id: pickerPage; PickerPage { onLogoutRequested: stack.replace(loginPage) } }
    Component { id: adminPage; AdminPage { onLogoutRequested: stack.replace(loginPage) } }

    Connections {
        target: backend
        function onNotification(message) {
            banner.show(message)
        }
    }

    InfoBanner { id: banner }
}
