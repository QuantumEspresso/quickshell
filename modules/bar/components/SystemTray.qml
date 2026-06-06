import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import qs.Core
import qs.Widgets
import "../../../colors" as ColorsModule

RowLayout {
    id: root

    function cleanIcon(icon) {
        if (!icon) return ""
 
        // usuń ?path=...
        let base = icon.split("?")[0]
 
        return base
    }

    function normalizeIcon(icon) {
        if (!icon) return ""
 
        let base = icon.split("?")[0]
 
        return base
    }

    property var colors: ColorsModule.Colors
    property bool trayOpen: false

    visible: SystemTray.items && SystemTray.items.values && SystemTray.items.values.length > 0
    spacing: 4

    Rectangle {
        clip: true
        height: 26
        radius: height / 2

        color: colors.surface_container
        border.color: colors.outline_variant
        border.width: 1

        Layout.preferredWidth: trayOpen ? (trayInner.implicitWidth + 16) : 0
        Layout.rightMargin: trayOpen ? 4 : 0
        opacity: trayOpen ? 1 : 0

        RowLayout {
            id: trayInner
            anchors.centerIn: parent
            spacing: 8

	    Tray {
	        iconSize: 16
		colors: root.colors
	    }
//            Repeater {
//                model: SystemTray.items.values

//delegate: MouseArea {
//    required property var modelData

//    width: 20
//    height: 20
//    hoverEnabled: true

//onClicked: {
//    Qt.callLater(() => {
//        Qt.createQmlObject(`
//            import Quickshell.Io
//            Process {
//                command: ["hyprctl", "dispatch", "focuswindow", "class:${modelData.id}"]
//                running: true
//            }
//        `, root)
//    })
//}

//    Image {
//        anchors.centerIn: parent
//        width: 16
//        height: 16

//        fillMode: Image.PreserveAspectFit
//        smooth: true

//        source: {
//            let icon = modelData.icon
//            return icon ? icon.split("?")[0] : "image://icon/application-x-executable"
//        }
//    }
//}

//            }
        }

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: 220
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on Layout.rightMargin {
            NumberAnimation {
                duration: 220
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        id: toggleBtn

        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        radius: height / 2

        color: colors.background
        border.width: 1
        border.color: colors.outline_variant

        Icon {
            anchors.centerIn: parent
            icon: Icons.arrowLeft
            font.pixelSize: 14

            color: colors.on_surface
            rotation: trayOpen ? 180 : 0

            Behavior on rotation {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: trayOpen = !trayOpen

            onEntered: toggleBtn.border.color = colors.primary
            onExited: toggleBtn.border.color = colors.outline_variant
        }

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }
    }
}
