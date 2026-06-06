pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    property string stateFile: runtimeDir + "/hypr-opaque-toggle"
    property string toggleScript: Quickshell.env("HOME") + "/.config/hypr/scripts/toggle_opacity.sh"

    property bool enabled: false

    // --- toggle ---
    function toggle(): void {
        toggleProc.running = true
    }

    function refresh(): void {
        checkProc.running = true
    }

    // --- toggle script ---
    Process {
        id: toggleProc
        command: [root.toggleScript]
        onExited: root.refresh()
    }

    // --- sprawdzanie stanu ---
    Process {
        id: checkProc
        command: ["bash", "-c", "[ -f '" + root.stateFile + "' ] && echo 1 || echo 0"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = text.trim() === "1"
            }
        }

        onExited: {
            if (exitCode !== 0)
                root.enabled = false
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
