import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services as Services
import "../../colors" as ColorsModule
import qs.components
import qs.modules.utilities

Item {
    id: utilitiesMenu
    property bool opened: false
    focus: true

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    property int controlCenterWidth: 450
    implicitWidth: opened ? controlCenterWidth : 0
    anchors.topMargin: 40
    x: 0

    function run(cmd) {
        proc.exec(cmd)
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Process { id: proc }

    FocusScope {
        anchors.fill: parent
        focus: utilitiesMenu.opened
        Keys.onEscapePressed: {
            utilitiesMenu.opened = false
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 1
	    radius:18
	    clip: true

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            id: slideContainer
            width: utilitiesMenu.controlCenterWidth
            height: parent.height
            color: "transparent"
            radius:18
	    clip: true

            x: utilitiesMenu.opened ? 0 : -width

            Behavior on x {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
		color: ColorsModule.Colors.surface_container_low

		radius:18
		clip: true

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.15) }
                    }
                }

            }

            layer.enabled: true

            Flickable {
                id: flickable
                anchors.fill: parent
                contentHeight: mainColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ColumnLayout {
                    id: mainColumn
		    width: parent.width
		    height: flickable.height
                    spacing: 0

		    ToolsSection {
			Layout.fillWidth: true
                        Layout.fillHeight: true
		    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 6
                width: 5
                radius: 2.5
                color: ColorsModule.Colors.surface_container_high
                opacity: flickable.moving ? 0.4 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(30, (flickable.height / flickable.contentHeight) * parent.height)
                    y: (flickable.contentY / flickable.contentHeight) * parent.height
                    radius: 2.5
                    color: ColorsModule.Colors.primary
                    opacity: 0.8

                    Behavior on y {
                        NumberAnimation { duration: 100 }
                    }
                }
            }
        }
    }
}
