import QtQuick
import Quickshell
import Quickshell.Io
import qs.services as Services
import "../../../colors" as ColorsModule

Rectangle {
    id: root

    radius: 13
    color: ColorsModule.Colors.surface_container
    implicitHeight: 28
    implicitWidth: contentRow.implicitWidth + 20
    clip: true

    property bool hovered: false

    // 🔥 nowy property reactive dla active network
    property var activeConnection: null

    // Funkcja do ręcznej aktualizacji activeConnection
    function updateActiveConnection() {
        let found =
            Services.Network.connections.find(c => c.active && c.type === "wifi")

        if (!found)
            found = Services.Network.connections.find(c => c.active)

        activeConnection = found ?? null
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: toggleProc.running = true
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        // =========================
        // IKONA + SIŁA
        // =========================
        Text {
	    id: baseText
            text: Services.Network.icon + " " + Services.Network.wifiStrength
            color: ColorsModule.Colors.on_surface
            font.pixelSize: 17
        }

        // =========================
        // SSID (STAŁA SZEROKOŚĆ + ANIMACJA)
        // =========================
        Item {
            id: ssidContainer
            width: 120
            height: parent.height
            clip: true
            visible: root.hovered

            Text {
		id: ssidText
		text: Services.Network.wifiLabel
                color: ColorsModule.Colors.on_surface
                font.pixelSize: 17
		anchors.verticalCenter: parent.verticalCenter

                x: 0

                SequentialAnimation on x {
                    running: root.hovered && ssidText.width > ssidContainer.width
                    loops: Animation.Infinite

                    PauseAnimation { duration: 800 }

                    NumberAnimation {
                        from: 0
                        to: -(ssidText.width - ssidContainer.width)
                        duration: 4000
                        easing.type: Easing.InOutQuad
                    }

                    PauseAnimation { duration: 800 }

                    NumberAnimation {
                        from: -(ssidText.width - ssidContainer.width)
                        to: 0
                        duration: 4000
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    Process {
        id: toggleProc
        command: ["qs", "ipc", "call", "networkPanel", "changeVisible", "wifi"]
    }
}
