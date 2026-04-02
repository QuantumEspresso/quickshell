import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services as Services
import "../colors" as ColorsModule

Item {
    id: root
    anchors.fill: parent
    focus: true

    property var c: ColorsModule.Colors
    function col(v,f){ return v || f }

    property string notesFile: Quickshell.env("HOME") + "/.config/quickshell/notes.md"
    property string markdown: ""
    property string html: ""
    property bool editMode: true

    function loadFile() { loadProc.running = true }
    function saveFile() { saveProc.running = true }
    function renderMarkdown() { renderProc.running = true }

    Component.onCompleted: loadFile()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Quick Notes"
                color: col(c.on_surface, "#ffffff")
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
            }

            Button {
                Layout.preferredWidth: 70

                onClicked: {
                    root.editMode = !root.editMode
                    if (!root.editMode)
                        root.renderMarkdown()
                }

                contentItem: Text {
                    text: root.editMode ? "Preview" : "Edit"
                    color: col(c.on_surface, "#0af")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }

                background: Rectangle {
                    radius: 10
                    color: col(c.primary_container, "#222")
                }
            }

            Button {
                Layout.preferredWidth: 50
                onClicked: root.saveFile()

                contentItem: Text {
                    text: "Save"
                    color: col(c.on_surface, "#0af")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }

                background: Rectangle {
                    radius: 10
                    color: col(c.primary_container, "#222")
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: col(c.surface_container, "#1c1c1c")
            clip: true

            Loader {
                anchors.fill: parent
                anchors.margins: 8
                sourceComponent: root.editMode ? editor : preview
            }
        }
    }

    Component {
        id: editor

        TextArea {
            text: root.markdown
            wrapMode: TextArea.Wrap
            selectByMouse: true
            color: col(c.on_surface, "#fff")
            selectionColor: col(c.primary, "#0af")
            selectedTextColor: "#fff"

            background: null

            onTextChanged: {
                root.markdown = text
                debounce.restart()
            }

            Timer {
                id: debounce
                interval: 700
                onTriggered: root.saveFile()
            }
        }
    }

    Component {
        id: preview

        ScrollView {
            clip: true

            Text {
                width: parent.width
                text: root.html
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                color: col(c.on_surface, "#fff")
            }
        }
    }

    // load
    Process {
        id: loadProc
        command: ["bash", "-c", "cat '" + root.notesFile + "' 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.markdown = text
                root.renderMarkdown()
            }
        }
    }

    // save
    Process {
        id: saveProc
        command: [
            "bash","-c",
            "mkdir -p $(dirname '" + root.notesFile + "') && printf \"%s\" \"$DATA\" > '" + root.notesFile + "'"
        ]

        environment: {
            "DATA": root.markdown
        }

        onExited: root.renderMarkdown()
    }

    // render markdown
    Process {
        id: renderProc
        command: [
            "bash","-c",
            "printf \"%s\" \"$DATA\" | pandoc -f markdown -t html"
        ]

        environment: {
            "DATA": root.markdown
        }

        stdout: StdioCollector {
            onStreamFinished: root.html = text
        }
    }
}
