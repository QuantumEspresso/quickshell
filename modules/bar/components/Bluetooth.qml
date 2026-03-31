import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.services as Services
import "../../../colors" as ColorsModule

Rectangle {
    id: root

    radius: 13
    color: ColorsModule.Colors.surface_container
    implicitHeight: 28
    implicitWidth: contentRow.implicitWidth + 10
    clip: true

    MouseArea {
        anchors.fill: parent
        onClicked: toggleProc.running = true
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        // =========================
        // IKONA
        // =========================
        Text {
            id: iconText
            text: bluetoothIcon
            color: ColorsModule.Colors.on_surface
            font.pixelSize: 17
        }

        // =========================
        // LABEL (dynamiczna szerokość z max + animacja)
        // =========================
        Item {
            id: labelContainer
            width: Math.min(label.implicitWidth + 10, 120) // maksymalna szerokość
            height: parent.height
            clip: true

            Text {
                id: label
                text: bluetoothLabel
                color: ColorsModule.Colors.on_surface
                font.pixelSize: 17
                anchors.verticalCenter: parent.verticalCenter

                x: 0

                SequentialAnimation on x {
                    id: scrollAnim
                    running: label.width > labelContainer.width
                    loops: Animation.Infinite

                    PauseAnimation { duration: 800 }

                    NumberAnimation {
                        from: 0
                        to: -(label.width - labelContainer.width)
                        duration: 4000
                        easing.type: Easing.InOutQuad
                    }

                    PauseAnimation { duration: 800 }

                    NumberAnimation {
                        from: -(label.width - labelContainer.width)
                        to: 0
                        duration: 4000
                        easing.type: Easing.InOutQuad
                    }
                }

                // Reset animacji gdy zmienia się tekst
                onTextChanged: {
                    x = 0
                    scrollAnim.running = label.width > labelContainer.width
                }
            }
        }
    }

    // =========================
    // LOGIKA LABEL I IKONY
    // =========================
    property string bluetoothLabel: {
        const adapter = Services.Bluetooth.defaultAdapter
        const device = Services.Bluetooth.activeDevice

        if (!adapter?.enabled)
            return "Off"
        if (device)
            return device.name
        return "On"
    }

    property string bluetoothIcon: {
        const adapter = Services.Bluetooth.defaultAdapter
        const device = Services.Bluetooth.activeDevice

        if (!adapter?.enabled)
            return "󰂲"     // wyłączony
        if (device)
            return ""     // połączony
        return "󰂯"         // włączony, brak połączenia
    }

    Process {
        id: toggleProc
        command: ["qs", "ipc", "call", "networkPanel", "changeVisible", "bluetooth"]
    }
}
