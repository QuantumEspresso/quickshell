import QtQuick
import qs.services as Services
import qs.Core
import Quickshell.Io
import "../../../colors" as ColorsModule

Rectangle {
    id: cpuRect
    radius: 13
    color: ColorsModule.Colors.surface_container
    implicitHeight: 28
    implicitWidth: rowContent.implicitWidth + 16

    Row {
        id: rowContent
        anchors.centerIn: parent
        spacing: 8

        // =========================
        // CPU (z temp na hover)
        // =========================
        Text {
            id: cpuText
	    font.pixelSize: 17
	    color: Services.System.tempColor(Services.System.temp)
            //color: ColorsModule.Colors.on_surface

            property bool hovered: false

            text: {
                const cpu = Math.round(Services.System.cpu)
                const temp = Math.round(Services.System.temp)

                return hovered
                    ? "  " + cpu + "%   " + temp + "°C"
                    : "  " + cpu + "%"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: cpuText.hovered = true
                onExited: cpuText.hovered = false

                onClicked: cpuProc.running = true
            }
        }

        // =========================
        // RAM
        // =========================

	Text {
            id: ramText
            font.pixelSize: 17
            color: Services.System.tempColor(Services.System.temp)

            property bool hovered: false

            text: {
                const ramPerc = Math.round(Services.System.ram)
                const ramPretty = Services.System.ramPretty

                return hovered
                    ? "  " + ramPerc + "%  (" + ramPretty + " GB)"
                    : "  " + ramPerc + "%"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: ramText.hovered = true
                onExited: ramText.hovered = false

                onClicked: cpuProc.running = true
            }
        }
        // =========================
        // GPU
	// =========================
	Text {
            id: gpuText
            font.pixelSize: 17
            color: Services.System.tempColor(Services.System.gpuTemp)

            property bool hovered: false

            visible: !isNaN(Services.System.gpu)

            text: {
                const usage = Math.round(Services.System.gpu)
                const temp = Services.System.gpuTemp

                if (hovered && !isNaN(temp))
                    return "󰢮  " + usage + "%   " + temp + "°C"

                return "󰢮  " + usage + "%"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: gpuText.hovered = true
                onExited: gpuText.hovered = false

                onClicked: gpuProcLauncher.running = true
            }
        }
    }

    // =========================
    // CPU CLICK (btop)
    // =========================
    Process {
        id: cpuProc
        command: ["bash", "-c", "hyprctl dispatch \"hl.dsp.workspace.toggle_special('btop')\""]
    }

    // =========================
    // GPU CLICK (nvtop)
    // =========================
    Process {
        id: gpuProcLauncher
        command: ["bash", "-c", "hyprctl dispatch \"hl.dsp.workspace.toggle_special('nvtop')\""]
    }

    // =========================
    // (opcjonalnie) animacja szerokości
    // =========================
    Behavior on implicitWidth {
        NumberAnimation { duration: 150 }
    }
}
