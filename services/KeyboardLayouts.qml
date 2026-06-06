pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property list<string> layouts: ["pl", "de", "jp"]
    property string current: ""
    property int currentIndex: 0

    function updateCurrent() {
        readCurrentProc.running = true
    }

    function rotateLayout() {
        if (layouts.length === 0) return

        currentIndex = (currentIndex + 1) % layouts.length
        let newLayout = layouts[currentIndex]

        setLayoutProc.command = [
            "bash", "-c",
            "hyprctl keyword input:kb_layout " + newLayout
        ]
        setLayoutProc.running = true

        current = newLayout
    }

    Process {
        id: readCurrentProc
        command: [
            "bash", "-c",
            "hyprctl -j devices | jq -r '.keyboards[] | select(.main==true) | .active_keymap'"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = text.trim()

                // mapowanie Hypr -> skrót
                const map = {
                    "Polish": "pl",
                    "German": "de",
                    "Japanese": "jp"
                }

                root.current = map[txt] ?? txt.toLowerCase()

                let idx = root.layouts.indexOf(root.current)
                if (idx !== -1) root.currentIndex = idx
            }
        }
    }

    Process {
        id: setLayoutProc
    }

    Component.onCompleted: updateCurrent()
}
