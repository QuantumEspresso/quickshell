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
CURRENT=$(gsettings get org.gnome.desktop.interface color-scheme)

if [ "$CURRENT" = "'prefer-dark'" ]; then
    gsettings set org.gnome.desktop.interface color-scheme default
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita
    kvantummanager --set KvArc
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
    kvantummanager --set KvArcDark
fi

systemctl --user restart xdg-desktop-portal 2>/dev/null
`
        ]
        onExited: detect() // odśwież stan po przełączeniu
    }

    Component.onCompleted: detect()
}
