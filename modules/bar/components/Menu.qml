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
        text: Services.Recorder.recording ? "󰻃 " : "󱄅 " 
        color: Services.Recorder.recording ? "#FF0036" : "#82AEF6"
        anchors.centerIn: parent
        font.pixelSize: 17
    }

    Process {
        id: toggleProc
        command: ["qs","ipc","call","controlCenter","changeVisible"]
    }

}
