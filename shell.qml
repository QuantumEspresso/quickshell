import QtQuick
import Quickshell
import qs.modules.network
import qs.modules.volume
import qs.modules.battery
import qs.modules.control
import qs.modules.utilities
import qs.modules.calendar
import qs.modules.media
import qs.modules.bar
import qs.modules.system
import Quickshell.Io
import qs.services as Services
import qs.components
import qs.Osd
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.wallpaper

ShellRoot {
    id: root
    
    GlobalShortcut {
        name: "mediaPlayPause"
        description: "Play/Pause media"
        onPressed: Services.Media.playPause()
    }

    GlobalShortcut {
        name: "mediaNext"
        description: "Next track"
        onPressed: Services.Media.next()
    }

    GlobalShortcut {
        name: "mediaPrev"
        description: "Previous track"
        onPressed: Services.Media.previous()
    }

    NotificationToasts {}
    CalendarWindow {}
    PanelWindow {
        focusable: true
        WlrLayershell.layer: WlrLayer.Bottom
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
    }
    Visualizer {
        id: visBottom
        anchorBottom: true
        visible: false
    }
    Visualizer {
        id: visTop
        anchorBottom: false
        visible: visBottom.visible
    }


    PanelWindow {
        id: rootPanel
        exclusionMode: ExclusionMode.Ignore
        implicitHeight: screen.height
	implicitWidth: screen.width
        anchors {
            top: true
            bottom: true
            left: true
	    right: true
        }
        color: "transparent"
        focusable: true

        Loader {
            id: mediaPanelLoader
            active: false
            anchors.horizontalCenter: parent.horizontalCenter
            sourceComponent: MediaPanel {
                id: mediaPanel
            }
            focus: true
        }

        PanelWindow {
            id: systemPanelLoader
            visible: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            color: "transparent"
            focusable: false

            anchors {
                right: true
                top: true
                bottom: true
            }

            implicitWidth: systemPanel.opened ? 450 : 0
            implicitHeight: screen.height

            SystemPanel {
                id: systemPanel
                anchors.fill: parent
            }
        }

        WallhavenWrapper{
            id: wallhavenWrapper
        }
        Loader {
            id: networkPanelLoader
            active: false
            anchors.top: parent.top
	    anchors.right: parent.right
	    anchors.topMargin: 40
            sourceComponent: NetworkPanel {
                id: networkPanel
            }
        }
        Loader {
            id: volumePanelLoader
            active: false
            anchors.top: parent.top
	    anchors.right: parent.right
	    anchors.topMargin: 40
            sourceComponent: VolumePanel {
                id: volumePanel
            }
        }
        
        Loader {
            id: batteryPanelLoader
            active: false
            anchors.top: parent.top
	    anchors.right: parent.right
	    anchors.topMargin: 40
            sourceComponent: BatteryPanel {
                id: batteryPanel
            }
        }

        OsdWindow {}

        PanelWindow{
            implicitHeight: 42
            implicitWidth: 0
            anchors {
                top: true
            }
            color: "transparent"
            mask: rootPanel.mask
        }

        TopBar{
            id: topBar
        }

        MouseArea {
            id: notesDrawerTrigger
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            height: 2
            z: 100
            width: 900

            onClicked: {
                notesDrawer.opened = !notesDrawer.opened
            }

            hoverEnabled: true

            Rectangle {
                anchors.fill: parent
                color: parent.containsMouse ? "#40FFFFFF" : "transparent"
                visible: parent.containsMouse
            }
        }

        Wallpaper{
            id: wallpaper
        }

        Loader {
            active: false
            id: controlCenterLoader
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            sourceComponent: ControlCenter {
                id: controlCenter
            }
            focus: true
        }
        Loader {
            active: false
            id: utilitiesMenuLoader
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            sourceComponent: UtilitiesMenu {
                id: utilitiesMenu
            }
            focus: true
        }

        property bool altHeld: false

        mask: Region{
            Region{
                item: mediaPanelLoader.active ? mediaPanelLoader : null
            }
            Region{
                item: systemPanelLoader.active ? systemPanelLoader : null
            }
            Region{
                item: topBar
            }
            Region {
                item: networkPanelLoader.item ? networkPanelLoader.item : null
            }
            Region {
                item: volumePanelLoader.item ? volumePanelLoader.item : null
            }
            Region {
                item: batteryPanelLoader.item ? batteryPanelLoader.item : null
            }
            Region{
                item: controlCenterLoader.active ? controlCenterLoader : null
            }
            Region{
                item: utilitiesMenuLoader.active ? utilitiesMenuLoader : null
            }
            Region{
                item: wallpaper.visible ? wallpaper : null
            }
        }
    }

    Connections {
        target: mediaPanelLoader.item
        function onOpenedChanged() {
            if (!mediaPanelLoader.item.opened) {
                closeTimer.start()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 600
        onTriggered: mediaPanelLoader.active = false
    }

    IpcHandler {
        target: "mediaPanel"

        function toggle(): void {
            if (!mediaPanelLoader.active) {
                mediaPanelLoader.active = true
                mediaPanelLoader.item.opened = true
            } else {
                mediaPanelLoader.item.opened = !mediaPanelLoader.item.opened
            }
        }
    }

    IpcHandler {
        target: "networkPanel"

        function changeVisible(tab: string): void {
            if (!networkPanelLoader.active)
                networkPanelLoader.active = true

            const panel = networkPanelLoader.item
            if (!panel)
                return

            if (panel.opened) {
                panel.opened = false
                return
            }

            if (tab === "wifi")
                panel.currentTab = 0
            else if (tab === "bluetooth")
                panel.currentTab = 1

            if (tab !== undefined)
                panel.opened = true
            else
                panel.opened = !panel.opened
        }
    }

    IpcHandler {
        target: "volumePanel"

        function changeVisible(tab: string): void {
            if (!volumePanelLoader.active)
                volumePanelLoader.active = true

            const panel = volumePanelLoader.item
            if (!panel)
                return

            if (panel.opened) {
                panel.opened = false
                return
            }

            if (tab === "sink")
                panel.currentTab = 0
            else if (tab === "source")
                panel.currentTab = 1

            if (tab !== undefined)
                panel.opened = true
            else
                panel.opened = !panel.opened
        }
    }

    IpcHandler {
        target: "systemPanel"
 
        function changeVisible(): void {
            systemPanel.opened = !systemPanel.opened
            systemPanelLoader.visible = systemPanel.opened
        }
    }
    
    IpcHandler {
        target: "batteryPanel"

        function changeVisible(): void {
            if (!batteryPanelLoader.active)
                batteryPanelLoader.active = true

            if (!batteryPanelLoader.item)
                return

            batteryPanelLoader.item.opened =
                !batteryPanelLoader.item.opened
        }
    }

    IpcHandler {
        target: "controlCenter"
        function changeVisible(): void {
            if (!controlCenterLoader.active) {
                controlCenterLoader.active = true
                controlCenterLoader.item.opened = true
            } else {
                controlCenterLoader.item.opened = !controlCenterLoader.item.opened
            }
        }
    }

    IpcHandler {
        target: "utilitiesMenu"
        function changeVisible(): void {
            if (!utilitiesMenuLoader.active) {
                utilitiesMenuLoader.active = true
                utilitiesMenuLoader.item.opened = true
            } else {
                utilitiesMenuLoader.item.opened = !utilitiesMenuLoader.item.opened
            }
        }
    }

    IpcHandler {
        target: "visBottom"

        function toggle() {
            visBottom.visible = !visBottom.visible
        }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle() {
            wallpaper.visible = !wallpaper.visible
        }
    }

    Timer {
        id: closeWindowSwitcherTimer
        interval: 300
        onTriggered: windowSwitcherLoader.active = false
    }

}
