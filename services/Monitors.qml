import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
Singleton {
    id: root

    property ListModel model: ListModel {}
    property int originalLayoutOriginX: 0
    property int originalLayoutOriginY: 0
    property real uiScale: 0.10
    property int revision: 0

    // =========================
    // MONITORS
    // =========================
    function refresh() {
        displayPoller.restart()
    }

    Process {
        id: displayPoller
        command: ["hyprctl", "monitors", "-j"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim())
                    root.model.clear()

                    let minX = 999999
                    let minY = 999999

                    for (let i = 0; i < data.length; i++) {
                        if (data[i].x < minX) minX = data[i].x
                        if (data[i].y < minY) minY = data[i].y
                    }

                    root.originalLayoutOriginX = minX !== 999999 ? minX : 0
                    root.originalLayoutOriginY = minY !== 999999 ? minY : 0

                    for (let i = 0; i < data.length; i++) {
                        let scl = data[i].scale !== undefined ? data[i].scale : 1.0
                        let normalizedX = (data[i].x - minX) * root.uiScale
                        let normalizedY = (data[i].y - minY) * root.uiScale

                        root.model.append({
                            name: data[i].name,
                            resW: data[i].width,
                            resH: data[i].height,
                            sysScale: scl,
                            rate: data[i].refreshRate,
                            uiX: normalizedX,
                            uiY: normalizedY,
                            disabled: data[i].disabled || false,
                            scale: data[i].scale || 1.0,
                            description: data[i].description || data[i].name
                        })
                    }
                } catch(e) {
                    console.log("ERROR PARSING MONITORS JSON:", e)
                }

                root.revision++
            }
        }
    }

    // =================================================
    // INPUT DEVICE MAPPING (STABLE, REACTIVE)
    // =================================================

    property var inputDeviceMap: ({})

    function getMappedMonitor(deviceName) {
        if (!deviceName) return "Off"
        return inputDeviceMap[deviceName] || "Off"
    }

    function reloadInputDeviceMap() {
        inputMapProc.running = false
        inputMapProc.running = true
    }

    function parseInputMap(text) {
        let map = {}
        let lines = text.trim().split("\n")

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim()
            if (!line) continue

            let parts = line.split("|")
            if (parts.length < 2) continue

            let dev = parts[0].trim()
            let mon = parts[1].trim()

            if (dev.length)
                map[dev] = mon
        }

        console.log("INPUT MAP:", JSON.stringify(map))
        inputDeviceMap = map
        inputDeviceMapChanged()
    }

    // =================================================
    // LOAD FILE
    // =================================================
    Process {
        id: inputMapProc

        command: [
            "bash","-c",
            "cat \"$HOME/.config/hypr/input-device-mapping.conf\" 2>/dev/null || true"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseInputMap(text)
            }
        }
    }

}
