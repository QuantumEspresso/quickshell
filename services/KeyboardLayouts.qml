pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property list<string> layouts: []        // lista dostępnych layoutów (np. pl,de,jp)
    property string current: ""             // aktualny layout (skrót)
    property int currentIndex: 0            // indeks w layouts

    // mapowanie hyprctl -> skrót
    property var hyprToXkbMap: ({ "Polish": "pl", "German": "de", "Japanese": "jp" })

    function updateLayouts(): void {
        readFileProc.exec(["/bin/bash", "-c", "grep XKBLAYOUT /etc/default/keyboard | cut -d'\"' -f2"]);
    }

    function updateCurrent(): void {
        readCurrentProc.exec(["/bin/bash", "-c", "hyprctl devices | grep 'active keymap' | head -n1 | awk -F': ' '{print $2}'"]);
    }

    function rotateLayout(): void {
        if (layouts.length === 0) return;
        currentIndex = (currentIndex + 1) % layouts.length;
        const newLayout = layouts[currentIndex];
        setLayoutProc.exec(["/bin/bash", "-c", "hyprctl keyword input:kb_layout " + newLayout]);
        current = newLayout;
    }

    Process {
        id: readFileProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const txt = text.trim();
                if (txt.length > 0) {
                    root.layouts = txt.split(",");
                    if (root.currentIndex >= root.layouts.length) root.currentIndex = 0;
                }
            }
        }
    }

    Process {
        id: readCurrentProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const txt = text.trim();
                if (txt.length > 0) {
                    // mapujemy hyprctl name -> skrót z layouts
                    const xkb = root.hyprToXkbMap[txt] ?? txt.toLowerCase();
                    root.current = xkb;

                    const idx = root.layouts.indexOf(xkb);
                    if (idx !== -1) root.currentIndex = idx;
                }
            }
        }
    }

    Process {
        id: setLayoutProc
        running: false
    }

    Component.onCompleted: {
        updateLayouts();
        updateCurrent();
    }
}
