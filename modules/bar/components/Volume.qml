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
    implicitWidth: rowContent.implicitWidth + 20
    clip: true

    Row {
        id: rowContent
        anchors.centerIn: parent
        spacing: 16

        // =========================
        // SYSTEM VOLUME
        // =========================
        Item {
            id: volZone
            width: volumeRow.implicitWidth
            height: 28
            property bool hovered: false

            Row {
                id: volumeRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // SLIDER (LEFT)
                Rectangle {
                    id: volSlider
                    height: 8
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorsModule.Colors.surface_variant

                    width: volZone.hovered ? 80 : 0
                    opacity: volZone.hovered ? 1 : 0
                    clip: true

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }

                    Rectangle {
                        id: volHandle
                        width: 12
                        height: 12
                        radius: 6
                        y: (volSlider.height - height) / 2
                        color: ColorsModule.Colors.primary

                        x: volSlider.width - width - (volText.volPerc / 100) * (volSlider.width - width)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onPressed: if (mouse.button === Qt.LeftButton) updateVolume(mouse.x)
                        onPositionChanged: if (pressed && mouse.buttons === Qt.LeftButton) updateVolume(mouse.x)
                        onClicked: if (mouse.button === Qt.RightButton) volMuteProc.running = true

                        onWheel: function(wheel) {
                            let delta = wheel.angleDelta.y > 0 ? 5 : -5
                            let newVol = volText.volPerc + delta
                            newVol = Math.max(0, Math.min(100, newVol))
                            volText.volPerc = newVol

                            setVolumeProc.command = ["bash", "-c",
                                "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (newVol / 100)
                            ]
                            setVolumeProc.running = true
                        }

                        function updateVolume(mouseX) {
                            let ratio = 1 - (mouseX / volSlider.width)
                            ratio = Math.max(0, Math.min(1, ratio))

                            let vol = Math.round(ratio * 100)
                            volText.volPerc = vol

                            setVolumeProc.command = ["bash", "-c",
                                "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (vol / 100)
                            ]
                            setVolumeProc.running = true
                        }
                    }
                }

                Text {
                    id: volText
                    font.pixelSize: 17
                    color: ColorsModule.Colors.on_surface

                    property int volPerc: 0
                    property bool volMuted: false

                    text: (volMuted ? "  " : "󰕾  ") + volPerc + "%"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton)
                                volMuteProc.running = true
                            else if (mouse.button === Qt.LeftButton)
                                toggleSink.running = true
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: volZone.hovered = true
                onExited: volZone.hovered = false
            }
        }

        // =========================
        // MICROPHONE
        // =========================
        Item {
            id: micZone
            width: micRow.implicitWidth
            height: 28
            property bool hovered: false

            Row {
                id: micRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    id: micSlider
                    height: 8
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorsModule.Colors.surface_variant

                    width: micZone.hovered ? 80 : 0
                    opacity: micZone.hovered ? 1 : 0
                    clip: true

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }

                    Rectangle {
                        id: micHandle
                        width: 12
                        height: 12
                        radius: 6
                        y: (micSlider.height - height) / 2
                        color: ColorsModule.Colors.primary

                        x: micSlider.width - width - (micText.micPerc / 100) * (micSlider.width - width)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onPressed: if (mouse.button === Qt.LeftButton) updateMic(mouse.x)
                        onPositionChanged: if (pressed && mouse.buttons === Qt.LeftButton) updateMic(mouse.x)
                        onClicked: if (mouse.button === Qt.RightButton) micMuteProc.running = true

                        onWheel: function(wheel) {
                            let delta = wheel.angleDelta.y > 0 ? 5 : -5
                            let newMic = micText.micPerc + delta
                            newMic = Math.max(0, Math.min(100, newMic))
                            micText.micPerc = newMic

                            setMicProc.command = ["bash", "-c",
                                "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (newMic / 100).toFixed(2)
                            ]
                            setMicProc.running = true
                        }

                        function updateMic(mouseX) {
                            let ratio = 1 - (mouseX / micSlider.width)
                            ratio = Math.max(0, Math.min(1, ratio))

                            let mic = Math.round(ratio * 100)
                            micText.micPerc = mic

                            setMicProc.command = ["bash", "-c",
                                "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (mic / 100).toFixed(2)
                            ]
                            setMicProc.running = true
                        }
                    }
                }

                Text {
                    id: micText
                    font.pixelSize: 17
                    color: ColorsModule.Colors.on_surface

                    property int micPerc: 0
                    property bool micMuted: false

                    visible: !isNaN(micPerc)
		    text: (micMuted ? " " : " ") + micPerc + "%"

		    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                       
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton)
                                micMuteProc.running = true
                            else if (mouse.button === Qt.LeftButton)
                                toggleSource.running = true
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: micZone.hovered = true
                onExited: micZone.hovered = false
            }
        }
    }

    // =========================
    // TIMER
    // =========================
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            volUpdateProc.running = true
            micUpdateProc.running = true
        }
    }

    // =========================
    // PROCESY
    // =========================
    Process { id: volMuteProc; command: ["bash", "-c", "~/.config/hypr/scripts/volume_mute.sh"] }
    Process { id: micMuteProc; command: ["bash", "-c", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"] }
    Process { id: setVolumeProc }
    Process { id: setMicProc }
    Process { id: runPavucontrol; command: ["pavucontrol"] }

    Process {
        id: volUpdateProc
        command: ["bash", "-c",
            "out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@); " +
            "vol=$(echo $out | awk '{print int($2*100)}'); " +
            "echo $out | grep -q MUTED && mute=1 || mute=0; " +
            "echo $vol $mute"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                volText.volPerc = parseInt(parts[0]) || 0
                volText.volMuted = parts[1] === "1"
            }
        }
    }

    Process {
        id: micUpdateProc
        command: ["bash", "-c",
            "out=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@); " +
            "vol=$(echo $out | awk '{print int($2*100)}'); " +
            "echo $out | grep -q MUTED && mute=1 || mute=0; " +
            "echo $vol $mute"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                const vol = parseInt(parts[0])
                micText.micPerc = isNaN(vol) ? 0 : vol
                micText.micMuted = parts[1] === "1"
            }
        }
    }

    Process {
        id: toggleSink
        command: ["qs", "ipc", "call", "volumePanel", "changeVisible", "sink"]
    }

    Process {
        id: toggleSource
        command: ["qs", "ipc", "call", "volumePanel", "changeVisible", "source"]
    }
}
