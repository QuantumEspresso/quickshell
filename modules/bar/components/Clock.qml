import QtQuick
import Quickshell.Io
import "../../../colors" as ColorsModule
import qs.services as Services

Rectangle {
    radius: 13
    color: ColorsModule.Colors.surface_container
    implicitHeight: 28
    implicitWidth: clock.implicitWidth + 16

    MouseArea {
        onClicked: toggleProc.running = true
        anchors.fill: parent
    }

    Text {
        id: clock
        anchors.centerIn: parent
        font.pixelSize: 17

	//text: Services.Time.format("d MMM • hh:mm AP")
	text: Services.Time.format("HH:mm:ss")
        color: ColorsModule.Colors.on_surface
    }

    Process {
        id: toggleProc
        command: ["qs", "ipc", "call", "calendarWindow", "toggle"]
    }
}
