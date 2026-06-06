import QtQuick
import Quickshell
import qs.components
import Quickshell.Io

PanelWindow {
    id: calendarWindow

    visible: false
    color: "transparent"

    anchors.top: true
    anchors.right: true
    margins.top: 0
    margins.right: 8

    implicitWidth: 1040
    implicitHeight: 380

    Calendar {
        anchors.fill: parent
    }

    IpcHandler {
        target: "calendarWindow"
        function toggle(): void {
            calendarWindow.visible = !calendarWindow.visible
        }

    }

}
