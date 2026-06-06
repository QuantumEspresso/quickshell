pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    property bool light: false // true = light mode, false = dark mode

    function detect() {
        detectProcess.running = true
    }

    function toggle() {
        toggleProcess.running = true
    }

    function changeWallpaper(path) {
        toggleWallpaper.path = path
        toggleWallpaper.running = true
    }

    Process {
        id: detectProcess
        command: ["bash", "-c", "gsettings get org.gnome.desktop.interface color-scheme"]

        stdout: StdioCollector {
            onStreamFinished: {
                theme.light = text.trim() !== "'prefer-dark'"
            }
        }
    }

    Process {
        id: toggleProcess
        command: [
            "bash", "-c",
            `
                ~/.config/quickshell/scripts/light-dark.sh theme
            `
        ]
        onExited: detect()
    }

    Process {
    id: toggleWallpaper

        property string path: ""
        
        command: [
            "bash",
            "-c",
            "exec ~/.config/quickshell/scripts/light-dark.sh wallpaper \"" + path + "\""
        ]
    }

    Component.onCompleted: detect()
}
