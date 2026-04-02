import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../colors" as ColorsModule

Item {
    id: root
    anchors.fill: parent

    property var c: ColorsModule.Colors
    function col(v,f){ return v || f }

    property var binds: []

    function reload() {
        genProc.running = true
    }

    Component.onCompleted: reload()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "  - SUPER, 󰘵  - ALT, 󰘴  - CTRL, 󰘶  - SHIFT, 󰌑  - ENTER\n  - TAB,   - printscreen, 󱕒  - scroll\nMB - Mouse Button"
                color: col(c.on_surface, "#ffffff")
                font.pixelSize: 16
                wrapMode: Text.Wrap
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: col(c.surface_container, "#1c1c1c")
            clip: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 8

                Column {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.binds

                        RowLayout {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: modelData.key
                                color: col(c.primary, "#0af")
                                font.family: "monospace"
                                Layout.preferredWidth: 150
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: modelData.action
                                color: col(c.on_surface, "#ccc")
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: genProc
        command: ["bash", "-c", "~/.config/quickshell/scripts/get_shortcuts.sh"]

        onExited: {
            readProc.running = true
        }
    }

    Process {
        id: readProc
        command: ["bash", "-c", "cat ~/.config/quickshell/keybindings.txt"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                const out = []

                for (let line of lines) {
                    if (!line.trim())
                        continue

                    const parts = line.split(/\s{2,}/)

                    if (parts.length >= 2) {
                        out.push({
                            key: parts[0].trim(),
                            action: parts.slice(1).join(" ").trim()
                        })
                    }
                }

                root.binds = out
            }
        }
    }
}
