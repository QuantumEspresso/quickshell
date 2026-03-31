pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var history: []
    property bool ready: false

    function refresh() {
        clipProc.running = false
        clipProc.running = true
    }

    function copy(text) {
        copyProc.command = ["wl-copy", text]
        copyProc.running = true
    }

    Process {
        id: copyProc
    }

    Process {
        id: clipProc
        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                let list = []

                for (let line of lines) {
                    if (!line) continue

                    const tab = line.indexOf("\t")
                    if (tab < 0) continue

                    const content = line.substring(tab + 1).trim()
                    list.push(content)
                }

                root.history = list
                root.ready = true
            }
        }
    }

    Component.onCompleted: refresh()
}
