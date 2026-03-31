import QtQuick
import Quickshell
import Quickshell.Io
import qs.services as Services
import "../../../colors" as ColorsModule

Rectangle {
    radius: 13
    color: ColorsModule.Colors.surface_container
    implicitHeight: 28
    implicitWidth: 40

    MouseArea {
        anchors.fill: parent
        onClicked: toggleProc.running = true
    }

    Text {
        id: memory
        text: "󰍉 "
        color: ColorsModule.Colors.on_surface
        anchors.centerIn: parent
        font.pixelSize: 17
    }

    Process {
        id: toggleProc
        command: ["qs","ipc","call","utilitiesMenu","changeVisible"]
    }

}
