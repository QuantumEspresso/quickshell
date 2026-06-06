import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../colors" as ColorsModule
import qs.services as Services

Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 160
    color: "transparent"
    radius: 18
    clip: true

    gradient: Gradient {
        GradientStop { position: 0.0; color: ColorsModule.Colors.primary_container }
        GradientStop { position: 1.0; color: Qt.darker(ColorsModule.Colors.primary_container, 1.1) }
    }

    Rectangle {
        width: parent.width * 0.4
        height: parent.height
        anchors.right: parent.right
        color: ColorsModule.Colors.secondary_container
        opacity: 0.1
    }

    Process { id: sessionProc }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // Avatar
            Item {
                width: 70
                height: 70

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "black"
                }

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    source: "file:///home/" + Services.System.username + "/.config/quickshell/picture.png"
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: false
                }

                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: avatarImage
                    maskSource: avatarMask
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Qt.rgba(1,1,1,0.15)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: Services.System.username
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    color: ColorsModule.Colors.on_primary_container
                }

                Text {
                    text: "Up time: " + Services.System.uptime
                    font.pixelSize: 13
                    opacity: 0.7
                    color: ColorsModule.Colors.on_primary_container
                }
            }
        }

        // SESSION BUTTONS
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            function run(cmd) {
                sessionProc.exec(["sh", "-c", cmd])
            }

            Repeater {
                model: [
                    { icon: "󰐥 ", cmd: ["systemctl","poweroff"] },
                    { icon: "󰜉 ", cmd: ["systemctl","reboot"] },
                    { icon: "󰍃 ", cmd: ["hyprctl","dispatch","exit"] },
                    { icon: "󰌾 ", cmd: ["hyprlock"] },
                    { icon: "󰒲 ", cmd: ["systemctl","suspend"] },
                    { icon: " ", cmd: ["systemctl","hibernate"] }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: ColorsModule.Colors.surface_container_high
                    opacity: 0.9

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.pixelSize: 16
                        color: ColorsModule.Colors.on_surface
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: parent.opacity = 1
                        onExited: parent.opacity = 0.9
                        onClicked: run(modelData.cmd)
                    }
                }
            }
        }
    }
}
