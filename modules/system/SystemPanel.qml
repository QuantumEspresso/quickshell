import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services as Services
import "../../colors" as ColorsModule

Item {
    id: systemPanel
    property bool opened: false
    property int systemPanelWidth: 450
    property var c: ColorsModule.Colors

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 40

    width: opened ? systemPanelWidth : 0

    Behavior on width {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#22000000"
        radius: 18
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 18

            // =========================
            // SYSTEM SECTION
            // =========================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: content.height
                color: "transparent"

                Column {
                    id: content
                    width: parent.width
                    spacing: 10

                    RowLayout {
                        width: parent.width

                        Text {
                            text: "System"
                            color: c.primary
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: c.outline
                            opacity: 0.4
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6

                        Text { text: "OS: " + Services.System.os; color: c.on_surface }
                        Text { text: "Kernel: " + Services.System.kernel; color: c.on_surface }
                        Text { text: "Uptime: " + Services.System.uptime; color: c.on_surface }
                        Text { text: "WM: " + Services.System.wm; color: c.on_surface }
                    }
                }
            }

        }
    }
}
