pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var apps: []
    property bool ready: false

    function refresh() {
        scanProc.running = false
        scanProc.running = true
    }

    Process {
        id: scanProc

        command: [
            "bash", "-c",
            `
dirs=(
/run/current-system/sw/share/applications
$HOME/.nix-profile/share/applications
/etc/profiles/per-user/$USER/share/applications
$HOME/.local/share/applications
/var/lib/flatpak/exports/share/applications
$HOME/.local/share/flatpak/exports/share/applications
)

for d in "\${dirs[@]}"; do
  [ -d "$d" ] || continue
  find "$d" -name "*.desktop" 2>/dev/null
done | while read file; do

name=$(grep -m1 "^Name=" "$file" | cut -d= -f2-)
icon=$(grep -m1 "^Icon=" "$file" | cut -d= -f2-)
exec=$(grep -m1 "^Exec=" "$file" | cut -d= -f2-)
terminal=$(grep -m1 "^Terminal=" "$file" | cut -d= -f2-)
nodisplay=$(grep -m1 "^NoDisplay=" "$file" | cut -d= -f2-)
hidden=$(grep -m1 "^Hidden=" "$file" | cut -d= -f2-)

[ "$nodisplay" = "true" ] && continue
[ "$hidden" = "true" ] && continue
[ -z "$name" ] && continue
[ -z "$exec" ] && continue

# usuń argumenty desktop file typu %u %f
exec=$(echo "$exec" | sed -E 's/%[a-zA-Z]//g')

printf '%s|%s|%s|%s\n' "$name" "$icon" "$exec" "$terminal"

done
`
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                let list = []

                for (let line of lines) {
                    if (!line) continue

                    const parts = line.split("|")
                    if (parts.length < 4) continue

                    list.push({
                        name: parts[0],
                        icon: parts[1],
                        exec: parts[2],
                        terminal: parts[3] === "true"
                    })
                }

                // sort alphabetically
                list.sort((a, b) => a.name.localeCompare(b.name))

                root.apps = list
                root.ready = true
            }
        }
    }

    Component.onCompleted: refresh()
}
